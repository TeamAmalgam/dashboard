#!/usr/bin/env ruby

require "sinatra"
require "sinatra/activerecord"

require "./models/init.rb"

get "/" do
  "Hello World"
end

get "/models" do
  "List of all models"
end

get "/models/:id" do
  "Viewing model #{params[:id]}"
end

post "/models/:id/run" do
  "Starting run on model #{params[:id]}"
end

post "/result" do
  "Expecting some sort of POST body"
end
