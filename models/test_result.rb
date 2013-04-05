class TestResult < ActiveRecord::Base
  belongs_to :model

  validates_presence_of :requested_at
  validates_presence_of :test_type
  validates :completed, :inclusion => { :in => [true, false] }

  def completed?; self.completed; end
  def pending?;  !self.completed; end

  def tarball_s3_link

  end

  def test_completed(data)
    # If the test has already completed, throw it away
    return if completed?

    # If the secret_key does not match, throw it away
    return unless data["secret_key"] == self.secret_key

    logger.info "Received result for test #{self.id}, updating records."

    self.update_attributes({
      :completed => true,
      :return_code => data["return_code"],
      :correct => (data["correct"] == 1),
      :started_at => Time.parse(data["started_at"]),
      :runtime_seconds => data["runtime_seconds"],
      :tarball_s3_key => data["tarball_s3_key"]
    })

    self.save
  end
end
