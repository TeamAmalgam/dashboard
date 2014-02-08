class Build < ActiveRecord::Base
  belongs_to :commit
  belongs_to :job

  validates_presence_of :job
  validates_presence_of :commit

  cattr_accessor :s3_bucket
  cattr_accessor :build_queue

  def s3_link
    return nil if self.jar_s3_key.nil?

    obj = @@s3_bucket.objects[self.jar_s3_key]
    obj.url_for(:read, :secure => true, :expires => 24.hours.to_i)
  end

  def return_code
    return job.return_code
  end

end
