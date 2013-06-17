class Commit < ActiveRecord::Base
  validates_presence_of :sha2_hash
  validates_uniqueness_of :sha2_hash

  validates_presence_of :time

  has_many :test_results
end
