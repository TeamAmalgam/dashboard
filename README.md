Amalgam Test Dashboard
======================
Repository for the dasboard located at:
http://amalgam.herokuapp.com/

The purpose of this dashboard is to allow for easy storage and running of 
correctness, performance, and continuous integration tests for Team Amalgam's 
improvements to the moolloy project.

Dependencies
------------
* ruby 2.0.0
* bundler
* postgres
* See Gemfile

Getting Started
---------------
1. `git clone https://github.com/TeamAmalgam/dashboard`
2. `bundle install`
3. Create a database for development.
4. Create a database.yml file in `config`. Example given in `config/database.example.yml`.
5. `rake db:migrate`

Deploying
---------
The Amalgam Test Dashboard is run on top of Heroku.

1. `git remote add heroku <HEROKU_GIT_REPO>`
2. `heroku maintenance:on`
3. `git push heroku master`
4. `heroku run rake db:migrate`
5. `heroku maintenance:off`

Useful Rake Tasks
-----------------
* `rake console`
* `rake db:create_migration NAME=<NAME>`
* `rake model:create`
