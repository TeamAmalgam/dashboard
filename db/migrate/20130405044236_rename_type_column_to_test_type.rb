class RenameTypeColumnToTestType < ActiveRecord::Migration
  def up
    rename_column :test_results, :type, :test_type
  end

  def down
    rename_column :test_results, :test_type, :type
  end
end
