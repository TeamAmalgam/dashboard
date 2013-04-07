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

config_file "config/auth.yml"
config_file "config/aws.yml"
config_file "config/git.yml"
config_file "config/hipchat.yml"

AWS.config(:access_key_id => settings.aws_access_key_id,
           :secret_access_key => settings.aws_secret_access_key)

sqs = AWS::SQS.new
Model.performance_queue = sqs.queues.named(settings.performance_sqs_queue)
Model.correctness_queue = sqs.queues.named(settings.correctness_sqs_queue)

s3 = AWS::S3.new
Model.s3_bucket = s3.buckets[settings.s3_bucket]
TestResult.s3_bucket = s3.buckets[settings.s3_bucket]

TestResult.hipchat_client = HipChat::Client.new(settings.hipchat_access_key)
TestResult.hipchat_room = settings.hipchat_room

["/", "/models"].each do |path|
  get path do
    @title = "Amalgam Dashboard"
    @models = Model.order("filepath")
    erb :"index"
  end
end

get "/models/:id" do
  @model = Model.where(:id => params[:id]).first

  halt 404, "404 - Page not found." if @model.nil?

  @test_results = @model.test_results.order("requested_at DESC")

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

  @model.run_test(params[:test_type])

  redirect to('/')
end

post "/result" do
  protected! if settings.production?

  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read

  # Find the TestResult associated with the response
  result = TestResult.where(:id => data["test_id"]).first

  halt 400, "400 - Bad request: submitted test result does not exist" if result.nil?

  # Pass the data to the model and let it handle the rest
  result.test_completed data

  "OK"
end

post "/repo/post_commit/#{settings.git_hook_secret}" do
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read

  commit = data["after"]
  repo = Repo.instance
  repo.head = commit
  repo.save!
end

post "/repo/post_commit/:secret" do
end
