class Model < ActiveRecord::Base
  JOB_DESCRIPTION_VERSION = 1

  validates_presence_of :filepath
  has_many :test_results
  has_one :last_test, :class_name => "TestResult",
                      :order => "requested_at DESC"
  has_one :last_completed_test, :class_name => "TestResult",
                                :order => "requested_at DESC",
                                :conditions => {:completed => true}

  cattr_accessor :s3_bucket
  cattr_accessor :performance_queue
  cattr_accessor :correctness_queue

  def friendly_name
    File.basename(self.filepath)
  end

  def s3_link
    return nil if self.s3_key.nil?
    
    obj = @@s3_bucket.objects[self.s3_key]
    obj.url_for(:read, :secure => true, :expires => 24.hours.to_i)
  end

  def upload(file_name, file)
    logger.info "Received request to upload file for model #{self.id}"

    hash = Digest::SHA2.hexdigest(file_name.to_s + Time.now.to_s).to_s
    key = "models/#{hash}.tar.gz"

    logger.info "Attempting to upload file to S3"

    @@s3_bucket.objects[key].write(file)

    logger.info "File upload successful"

    self.s3_key = key
    self.save!
  end

  def run_test(test_type)
    if test_type == "CORRECTNESS"
      test_type = TestResult::TestTypes::CORRECTNESS
    elsif test_type == "PERFORMANCE"
      test_type = TestResult::TestTypes::PERFORMANCE
    else
      raise "Invalid Test Type."
    end

    raise "No model uploaded." unless self.s3_key

    commit = Repo.instance.head

    test_result = self.test_results.create(:requested_at => DateTime.now,
                                           :test_type => test_type,
                                           :commit => commit,
                                           :completed => false)
    job_description = {
      :version => JOB_DESCRIPTION_VERSION,
      :test_id => test_result.id,
      :commit => commit,
      :model_s3_key => self.s3_key,
    }.to_yaml

    queue = case test_type
              when TestResult::TestTypes::CORRECTNESS then @@correctness_queue
              when TestResult::TestTypes::PERFORMANCE then @@performance_queue
            end

    sent_message = queue.send_message(job_description)
    
    test_result.secret_key = sent_message.id
    test_result.save
  end
end
