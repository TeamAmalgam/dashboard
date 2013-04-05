#!/usr/bin/env ruby

require "sinatra"
require "sinatra/activerecord"

require "./models/init.rb"

get "/" do
  @title = "Amalgam Dashboard"
  erb :"index"
end

get "/models" do
  @title = "Amalgam Dashboard - Model List"
  @models = Model.all
  erb :"models_list"
end

get "/models/:id" do
  @model = Model.where(:id => params[:id]).first

  halt 404, "404 - Page not found."  if @model.nil?

  @test_results = @model.test_results.order("time DESC")

  @title = "Amalgam Dashboard - Model #{params[:id]}"
  erb :"model_details"
end

post "/models/:id/run" do
  redirect to('/models')
end

post "/result" do
  "Expecting some sort of POST body"
end
