class TestResult < ActiveRecord::Base
  belongs_to :model

  def tarball_s3_link

  end
end
