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
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read

  # Find the TestResult associated with the response
  result = TestResult.find(data["test_id"])

  # Pass the data to the model and let it handle the rest
  result.test_completed data

  "OK"
end
