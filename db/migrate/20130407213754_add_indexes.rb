class AddIndexes < ActiveRecord::Migration
  def up
    add_index :test_results, :model_id
    add_index :test_results, :requested_at
  end

  def down
    remove_index :test_results, :requested_at
    remove_index :test_results, :model_id
  end
end
