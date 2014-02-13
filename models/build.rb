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

    # If the build was successful then we will queue up CI jobs
    # for each model enabled for CI.
    if data["return_code"] == 0
      Model.where(:ci_enabled => true).all.each do |model|
        unless model.s3_key.nil?
          model.run_test(TestRun::TestTypes::CONTINUOUS_INTEGRATION, self.commit.sha2_hash)
        end
      end
    end
  end

  def queue
    super(@@build_queue, :build, {})
  end
end
