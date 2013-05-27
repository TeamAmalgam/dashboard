class AddCommitToTestResults < ActiveRecord::Migration
  def up
    add_column :test_results, :commit, :string
  end

  def down
    remove_column :test_results, :commit
  end
end
