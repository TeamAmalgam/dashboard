class TestResult < ActiveRecord::Base
  belongs_to :model
  
  module TestTypes
    CORRECTNESS = 0
    PERFORMANCE = 1 

    VALID_TYPES = (0..1)
  end

  validates_presence_of :requested_at
  validates_presence_of :test_type
  validates :test_type, :inclusion => { :in => TestTypes::VALID_TYPES }
  validates :completed, :inclusion => { :in => [true, false] }

  cattr_accessor :hipchat_client
  cattr_accessor :hipchat_room
  cattr_accessor :s3_bucket

  def completed?; self.completed; end
  def pending?;  !self.completed; end

  def icon
    return "icon-question-sign" if self.pending?
    return "icon-ok" if self.correct?
    "icon-remove"
  end

  def row_class
    return "warning" if self.pending?
    return "success" if self.correct?
    "error"
  end

  def tarball_s3_link
    return nil if self.tarball_s3_key.nil?

    obj = @@s3_bucket.objects[self.tarball_s3_key]
    obj.url_for(:read, :secure => true, :expires => 24.hours.to_i)
  end

  def test_completed(data)
    # If the test has already completed, throw it away
    return if completed?

    # If the secret_key does not match, throw it away
    return unless data["secret_key"] == self.secret_key

    logger.info "Received result for test #{self.id}, updating records."

    correct = data["correct"] == 1
    runtime_seconds = data["runtime_seconds"]

    self.update_attributes({
      :completed => true,
      :return_code => data["return_code"],
      :correct => correct,
      :started_at => Time.parse(data["started_at"]),
      :runtime_seconds => runtime_seconds,
      :tarball_s3_key => data["tarball_s3_key"]
    })

    self.save

    TestResult.notify_hipchat!(self.id, self.model.friendly_name, runtime_seconds, correct)
  end

private

  def self.notify_hipchat!(id, name, time, correct)
    client = @@hipchat_client
    room = @@hipchat_room

    colour = correct ? "green" : "red"
    result = correct ? "success" : "fail"

    message = "Test run #{id} completed with result #{result}. Model #{name} ran in #{time} seconds."

    client[room].send("Dashboard", message, :color => colour)
  end

end
