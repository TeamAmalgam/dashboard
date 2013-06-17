class Model < ActiveRecord::Base
  JOB_DESCRIPTION_VERSION = 1

  validates_presence_of :filepath
  validate :ci_enabled_requires_model

  has_many :test_results
  has_one :last_test, :class_name => "TestResult",
                      :order => "requested_at DESC"
  has_one :last_completed_test, :class_name => "TestResult",
                                :order => "requested_at DESC",
                                :conditions => {:completed => true}
  has_one :last_correct_test, :class_name => "TestResult",
                              :order => "requested_at DESC",
                              :conditions => {:completed => true, :correct => true}

  cattr_accessor :s3_bucket
  cattr_accessor :performance_queue
  cattr_accessor :correctness_queue
  cattr_accessor :ci_queue

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
    key = case file_name.to_s
        when /\.tar\.gz\z/i then "models/#{hash}.tar.gz"
        when /\.tar\.bz2\z/i then "models/#{hash}.tar.bz2"
        else raise "Invalid file format. Expected tar.gz or tar.bz2"
      end

    valid_file = case file_name.to_s
                   when /\.tar\.gz\z/i then validate_gzip(file)
                   when /\.tar\.bz2\z/i then validate_bzip2(file)
                 end

    raise "File type does not match extension." unless valid_file

    logger.info "Attempting to upload file to S3"

    @@s3_bucket.objects[key].write(file)

    logger.info "File upload successful"

    self.s3_key = key
    self.save!
  end

  def run_test(test_type, commit_hash = nil)
    raise "No model uploaded." unless self.s3_key

    commit = nil
    if commit_hash.nil?
      commit = Repo.instance.commit
    else
      commit = Commit.where(:sha2_hash => commit_hash).first
    end

    test_result = self.test_results.create(:requested_at => DateTime.now,
                                           :test_type => test_type,
                                           :commit_id => commit.id,
                                           :completed => false)
    job_description = {
      :version => JOB_DESCRIPTION_VERSION,
      :test_id => test_result.id,
      :commit => commit.sha2_hash,
      :model_s3_key => self.s3_key,
    }.to_yaml

    queue = case test_type
              when TestResult::TestTypes::CORRECTNESS then @@correctness_queue
              when TestResult::TestTypes::PERFORMANCE then @@performance_queue
              when TestResult::TestTypes::CONTINUOUS_INTEGRATION then @@ci_queue
            end

    sent_message = queue.send_message(job_description)

    test_result.secret_key = sent_message.id
    test_result.save
  end

  private

  def ci_enabled_requires_model
    if ci_enabled? && self.s3_key.nil?
      errors.add(:ci_enabled, "must not be true if no model is uploaded")
    end
  end

  def validate_gzip(file)
    magic = file.read(2)
    file.rewind

    return false if magic.nil?
    return (magic == [0x1F, 0x8B].pack("CC"))
  end

  def validate_bzip2(file)
    magic = file.read(3)
    file.rewind

    return false if magic.nil?

    return (magic == "BZh")
  end
end
