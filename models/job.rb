class Job < ActiveRecord::Base
  belongs_to :commit

  JOB_DESCRIPTION_VERSION = 2

  protected

  def start
    self.update_attributes!({
      :started_at => Time.now
    })
  end

  def finish(data)
    raise "Bad Request." unless data["secret_key"] == self.secret_key

    self.update_attributes!({
      :finished_at => Time.now,
      :return_code => data["return_code"],
      :result_s3_key => data["result_s3_key"]
    })
  end

  def queue(sqs_queue, job_type, additional_params)
    job_description = {
      :version => JOB_DESCRIPTION_VERSION,
      :job_id => self.id,
      :job_type => job_type,
      :commit => self.commit.sha2_hash
    }.merge(additional_params).to_yaml

    sent_message = sqs_queue.send_message(job_description)
    
    self.update_attributes!({
      :requested_at => Time.now,
      :secret_key => sent_message.id
    })
  end
end
