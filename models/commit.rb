class Commit < ActiveRecord::Base
  validates_presence_of :sha2_hash
  validates_uniqueness_of :sha2_hash

  validates_presence_of :time

  has_many :test_results
  has_many :builds
  has_one :last_build, :class_name => "Build",
                       :order => "requested_at DESC"
end
