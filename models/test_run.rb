require_relative 'job'

class TestRun < Job
  belongs_to :model

  module TestTypes
    CORRECTNESS = 0
    PERFORMANCE = 1
    CONTINUOUS_INTEGRATION = 2
    VALID_TYPES = (0..2)
  end

  validates_presence_of :test_type
  validates :test_type, :inclusion => { :in => TestTypes::VALID_TYPES }

  cattr_accessor :hipchat_client
  cattr_accessor :hipchat_room
  cattr_accessor :s3_bucket
  cattr_accessor :correctness_queue
  cattr_accessor :performance_queue
  cattr_accessor :ci_queue

  def completed?; !self.return_code.nil?; end
  def pending?; self.return_code.nil?; end

  def tarball_s3_link
    return nil if self.result_s3_key.nil?

    obj = @@s3_bucket.objects[self.result_s3_key]
    obj.url_for(:read, :secure => true, :expires => 24.hours.to_i)
  end

  def start
    super
  end

  def finish(data)
    return if completed?
    
    super(data)
   
    correct = data["correct"] == 1

    self.update_attributes({
      :correct => (data["correct"] == 1),
      :real_time_seconds => data["real_time_seconds"],
      :cpu_time_seconds => data["cpu_time_seconds"],
    })
  end

  def queue
    sqs_queue = case self.test_type
                  when TestRun::TestTypes::CORRECTNESS then @@correctness_queue
                  when TestRun::TestTypes::PERFORMANCE then @@performance_queue
                  when TestRun::TestTypes::CONTINUOUS_INTEGRATION then @@ci_queue
                end
    super(sqs_queue, :run, { 
      :model_id => self.model_id,
      :jar_file_key => self.commit.last_good_build.result_s3_key,
      :model_file_key => self.model.s3_key
    })
  end

private

  def self.notify_hipchat(id, name, total_seconds, total_cpu_seconds, correct)
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
