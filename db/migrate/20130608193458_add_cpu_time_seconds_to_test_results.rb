class AddCpuTimeSecondsToTestResults < ActiveRecord::Migration
  def up
    add_column :test_results, :cpu_time_seconds, :integer
  end

  def down
    remove_column :test_results, :cpu_time_seconds
  end
end
