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

desc "Opens a console that loads the Sinatra environment"
task :console do
  exec 'bundle exec tux' if settings.development?
  exec 'irb -r "./app"'
end
