require "./app"
require "sinatra/activerecord/rake"

namespace :model do

  desc "Create a new model in the DB with the given filepath"
  task :create do
    name = ENV["NAME"]
    abort("no NAME specified. Use `rake model:create NAME=aerospace/apollo.als`") if !name

    model = Model.create(:filepath => name)
    model.save

    puts "Created model #{model.friendly_name} with ID #{model.id}"
  end

end

namespace :test_result do

  desc "Dumps out all the (completed and correct) test results in CSV format"
  task :dump do
    # Temporarily disable the logger
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    puts "\"ID\",\"Model\",\"Test Type\",\"Commit\",\"Commit Time\",\"Requested At\",\"Started At\",\"Real Time (s)\",\"CPU Time (s)\"" 
    TestRun.where(:correct => true)
           .includes(:model)
           .includes(:commit)
           .find_each do |t|
      test_type = case t.test_type
                  when TestRun::TestTypes::PERFORMANCE
                    "Performance"
                  when TestRun::TestTypes::CORRECTNESS
                    "Correctness"
                  when TestRun::TestTypes::CONTINUOUS_INTEGRATION
                    "CI"
                  else
                    "Unknown"
                  end
      commit = t.commit.nil? ? "Unknown" : t.commit.sha2_hash
      commit_time = t.commit.nil? ? "Unknown" : t.commit.time

      entry = [t.id,
               t.model.friendly_name,
               test_type,
               commit,
               commit_time,
               t.requested_at,
               t.started_at,
               t.runtime_seconds,
               t.cpu_time_seconds
               ].map{|a| "\"#{a}\""}
                .join(",")
      puts entry
    end

    # Enable logger
    ActiveRecord::Base.logger = old_logger
  end

end

desc "Opens a console that loads the Sinatra environment"
task :console do
  exec 'bundle exec tux' if settings.development?
  exec 'pry -r "./app"'
end
