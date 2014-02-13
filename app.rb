#!/usr/bin/env ruby

require "sinatra"
require "sinatra/activerecord"
require "sinatra/config_file"
require "sinatra/link_header"

require "acts_as_singleton"
require "aws-sdk"
require "hipchat"

require_relative "helpers/init"
require_relative "models/init"

# Configure settings from environment variables.
set :aws_access_key_id, ENV['AWS_ACCESS_KEY_ID']
set :aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY']
set :build_sqs_queue, ENV['BUILD_SQS_QUEUE']
set :performance_sqs_queue, ENV['PERFORMANCE_SQS_QUEUE']
set :correctness_sqs_queue, ENV['CORRECTNESS_SQS_QUEUE']
set :ci_sqs_queue, ENV['CI_SQS_QUEUE']
set :s3_bucket, ENV['S3_BUCKET']
set :hipchat_access_key, ENV['HIPCHAT_ACCESS_KEY']
set :hipchat_room, ENV['HIPCHAT_ROOM']
set :auth_username, ENV['AUTH_USERNAME']
set :auth_password, ENV['AUTH_PASSWORD']
set :git_hook_secret, ENV['GIT_HOOK_SECRET']
set :ga_tracking_code, ENV['GA_TRACKING_CODE']
set :ga_domain, ENV['GA_DOMAIN']

# Read settings from config files if they exist.
config_file "config/auth.yml"
config_file "config/aws.yml"
config_file "config/ga.yml"
config_file "config/git.yml"
config_file "config/hipchat.yml"

AWS.config(:access_key_id => settings.aws_access_key_id,
           :secret_access_key => settings.aws_secret_access_key)

sqs = AWS::SQS.new
TestRun.performance_queue = sqs.queues.named(settings.performance_sqs_queue)
TestRun.correctness_queue = sqs.queues.named(settings.correctness_sqs_queue)
TestRun.ci_queue = sqs.queues.named(settings.ci_sqs_queue)
Build.build_queue = sqs.queues.named(settings.build_sqs_queue)

s3 = AWS::S3.new
Model.s3_bucket = s3.buckets[settings.s3_bucket]
TestRun.s3_bucket = s3.buckets[settings.s3_bucket]
Build.s3_bucket = s3.buckets[settings.s3_bucket]

unless settings.hipchat_access_key.nil? || settings.hipchat_room.nil?
  TestRun.hipchat_client = HipChat::Client.new(settings.hipchat_access_key)
  TestRun.hipchat_room = settings.hipchat_room
  Worker.hipchat_client = HipChat::Client.new(settings.hipchat_access_key)
  Worker.hipchat_room = settings.hipchat_room
end

set :static, false

get "/" do
    @title = "Amalgam Dashboard"
    erb :"index"
end

get "/models" do
    @title = "Amalgam Dashboard - Models"
    @models = Model.order("filepath").includes(:last_test, :last_completed_test)
    erb :"models_list"
end

get "/models/:id" do
  @model = Model.where(:id => params[:id]).first

  halt 404, "404 - Page not found." if @model.nil?

  @test_runs = @model.test_runs.order("requested_at DESC")

  @title = "Amalgam Dashboard - Models - #{@model.friendly_name}"
  erb :"model_details"
end

post "/models/:id/upload" do
  protected! if settings.production?

  @model = Model.where(:id => params[:id]).first

  halt 404, "404 - Page not found." if @model.nil?

  @model.upload(params[:file][:filename], params[:file][:tempfile])

  redirect to("/models/#{@model.id}")
end

post "/models/:id/run" do
  protected! if settings.production?

  @model = Model.where(:id => params[:id]).first

  halt 404, "404 - Page not found." if @model.nil?

  test_type = case params[:test_type]
                when "CORRECTNESS" then TestRun::TestTypes::CORRECTNESS
                when "PERFORMANCE" then TestRun::TestTypes::PERFORMANCE
              end

  @model.run_test(test_type)

  redirect to('/models')
end

post "/repo/post_commit/#{settings.git_hook_secret}" do
  request.body.rewind  # in case someone already read it
  data = JSON.parse(params[:payload])

  data["commits"].each do |commit|
    if Commit.where(:sha2_hash => commit["id"]).first.nil?
      commit_obj = Commit.create!(:sha2_hash => commit["id"],
                                  :time => commit["timestamp"],
                                  :comment => commit["message"])

      # If this commit has not been built, then request a build.
      if commit_obj.last_build.nil?
        commit_obj.request_build
      end
    end
  end
end

post "/repo/post_commit/:secret" do
end

get "/workers" do
  @workers = Worker.order(:id).all
  @title = "Workers"

  erb :workers_list
end

post "/workers/register" do
  protected! if settings.production?

  request.body.rewind
  data = JSON.parse request.body.read

  worker = Worker.create(:last_heartbeat => Time.now,
                         :hostname => data["hostname"])

  Worker.notify_hipchat!(worker.id, worker.hostname, "registered")

  {:worker_id => worker.id}.to_json
end

post "/workers/:id/heartbeat" do
  protected! if settings.production?

  request.body.rewind
  data = JSON.parse request.body.read

  worker = Worker.where(:id => params[:id]).first

  halt 400, "400 - Bad request: worker does not exist" if worker.nil?

  worker.heartbeat(Time.now, data["job_id"])

  "OK"
end

post "/workers/:id/unregister" do
  protected! if settings.production?

  worker = Worker.where(:id => params[:id]).first
  Worker.notify_hipchat!(worker.id, worker.hostname, "unregistered")
  worker.delete
end

get "/commits" do
  @commits = Commit.order("time DESC").all
  @title = "Commits"

  erb :commits_list
end

get "/commits/:id" do
  @commit = Commit.where(:id => params[:id]).first
  @builds = @commit.builds.order("requested_at DESC").all

  erb :commit_details
end

post "/commits/:id/build" do
  protected! if settings.production?

  puts "Running Build"

  @commit = Commit.where(:id => params[:id]).first
  
  halt 400, "400 - No such commit." if @commit.nil?

  @commit.request_build
  
  redirect to("/commits/#{@commit.id}")
end

post "/jobs/:id/start" do
  protected! if settings.production?

  @job = Job.where(:id => params[:id]).first

  @job.start

  "OK"
end

post "/jobs/:id/finish" do
  protected! if settings.production?

  @job = Job.where(:id => params[:id]).first
  
  data = JSON.parse request.body.read

  @job.finish(data)

  "OK"
end
