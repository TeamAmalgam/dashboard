class TestResult < ActiveRecord::Base
  belongs_to :model
  has_one :worker
  belongs_to :commit
  belongs_to :job

  module TestTypes
    CORRECTNESS = 0
    PERFORMANCE = 1 
    CONTINUOUS_INTEGRATION = 2
    VALID_TYPES = (0..2)
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
    cpu_time_seconds = data["cpu_time_seconds"]

    self.update_attributes({
      :completed => true,
      :return_code => data["return_code"],
      :correct => correct,
      :started_at => Time.parse(data["started_at"]),
      :runtime_seconds => runtime_seconds,
      :cpu_time_seconds => cpu_time_seconds,
      :tarball_s3_key => data["tarball_s3_key"]
    })

    self.save

    TestResult.notify_hipchat!(self.id, self.model.friendly_name, runtime_seconds, cpu_time_seconds, correct)
  end

private

  def self.notify_hipchat!(id, name, total_seconds, total_cpu_seconds, correct)
    client = @@hipchat_client
    room = @@hipchat_room

    colour = correct ? "green" : "red"
    result = correct ? "success" : "fail"

    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)

    time = format("%02d:%02d:%02d", hours, minutes, seconds)

    cpu_time = "unknown"
    if !total_cpu_seconds.nil?
      cpu_seconds = total_cpu_seconds % 60
      cpu_minutes = (total_cpu_seconds / 60) % 60
      cpu_hours = total_cpu_seconds / (60 * 60)

      cpu_time = format("%02d:%02d:%02d", cpu_hours, cpu_minutes, cpu_seconds)
    end

    message = "Test run #{id} completed with result #{result}. Model #{name} ran in #{time} (cpu: #{cpu_time})."

    client[room].send("Dashboard", message, :color => colour) unless client.nil? || room.nil?
  end

end
