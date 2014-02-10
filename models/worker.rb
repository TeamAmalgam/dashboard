class Worker < ActiveRecord::Base
  validates_presence_of :hostname
  belongs_to :job

  cattr_accessor :hipchat_client
  cattr_accessor :hipchat_room

  before_create { |worker| worker.last_state_change_time = Time.now }

  def heartbeat(time,job_id)
    old_job_result_id = self.job_id

    if !job_result_id.nil?
      job = TestRun.where(:id => job_id).first

      raise "Unknown Job" if job.nil?
      self.job = job
    else
      self.job = nil
    end

    if old_job_id != self.job_id
      self.last_state_change_time = time
    end
    
    self.last_heartbeat = time

    self.save!
  end

  def self.running_count
    self.where("job_id IS NOT NULL").count
  end

  def self.idle_count
    self.where(:job_id => nil).count
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
