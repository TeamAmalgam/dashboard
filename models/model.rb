class Model < ActiveRecord::Base
  validates_presence_of :filepath
  
  has_many :test_results

  def friendly_name
    File.basename(self.filepath)
  end

  def s3_link
    
  end
end
