class AddRequestAtAndStartedAtColumns < ActiveRecord::Migration
  def up
    remove_column :test_results, :time
    add_column :test_results, :requested_at, :timestamp
    add_column :test_results, :started_at, :timestamp
  end

  def down
    remove_column :test_results, :started_at
    remove_column :test_results, :requested_at
    add_column :test_results, :time, :timestamp
  end
end
