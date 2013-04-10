class Worker < ActiveRecord::Base
  validates_presence_of :hostname
  belongs_to :test_result

  def heartbeat(time, test_result_id)
    if !test_result_id.nil?
      test_result = TestResult.where(:id => test_result_id).first

      raise "Unknown TestResult" if test_result.nil?
      self.test_result = test_result
    else
      self.test_result = nil
    end

    self.last_heartbeat = time

    self.save!
  end
end
