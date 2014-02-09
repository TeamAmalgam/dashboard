require_relative 'job'

class Build < Job
  belongs_to :commit

  validates_presence_of :commit

  cattr_accessor :s3_bucket
  cattr_accessor :build_queue

  def s3_link
    return nil if self.result_s3_key.nil?

    obj = @@s3_bucket.objects[self.result_s3_key]
    obj.url_for(:read, :secure => true, :expires => 24.hours.to_i)
  end

  def start
    super
  end

  def finish(data)
    super(data)
  end

  def queue
    super(@@build_queue, :build, {})
  end
end
