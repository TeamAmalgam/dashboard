class Commit < ActiveRecord::Base
  validates_presence_of :sha2_hash
  validates_uniqueness_of :sha2_hash

  validates_presence_of :time

  has_many :test_results
  has_many :builds
  has_one :last_build, :class_name => "Build",
                       :order => "requested_at DESC"
  has_one :last_good_build, :class_name => "Build",
                            :order => "requested_at DESC",
                            :conditions => { :return_code => 0 }

  def request_build
    build = self.builds.create!(:commit_id => self.id)
    build.queue
  end
end
