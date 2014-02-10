class ReplaceTestResultIdWithJobId < ActiveRecord::Migration
  def change
    add_column :workers, :job_id, :integer
    remove_column :workers, :test_result_id
  end
end
