class Job < ActiveRecord::Base
  has_one :build
  has_one :test_result 
end
