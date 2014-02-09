class Worker < ActiveRecord::Base
  validates_presence_of :hostname
  belongs_to :test_result

  cattr_accessor :hipchat_client
  cattr_accessor :hipchat_room

  before_create { |worker| worker.last_state_change_time = Time.now }

  def heartbeat(time, test_result_id)
    old_test_result_id = self.test_result_id

    if !test_result_id.nil?
      test_result = TestRun.where(:id => test_result_id).first

      raise "Unknown TestRun" if test_result.nil?
      self.test_result = test_result
    else
      self.test_result = nil
    end

    if old_test_result_id != self.test_result_id
      self.last_state_change_time = time
    end
    
    self.last_heartbeat = time

    self.save!
  end

  def self.running_count
    self.where("test_result_id IS NOT NULL").count
  end

  def self.idle_count
    self.where(:test_result_id => nil).count
  end

  def self.failing_count
    self.where("last_heartbeat < ?", 10.minutes.ago).count
  end

  def self.notify_hipchat!(id, host, action)
    client = @@hipchat_client
    room = @@hipchat_room

    message = "Worker #{id} on host #{host} just #{action}."

    client[room].send("Worker", message) unless client.nil? || room.nil?
  end
end
