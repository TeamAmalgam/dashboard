class AddAlgorithmToTestRuns < ActiveRecord::Migration
  def change
    add_column :jobs, :algorithm, :integer
  end
end
