class AddCommentToCommits < ActiveRecord::Migration
  def change
    add_column :commits, :comment, :string
  end
end
