class DeleteTestResults < ActiveRecord::Migration
  def change
    drop_table :test_results
  end
end
