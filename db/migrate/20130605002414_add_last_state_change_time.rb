class AddLastStateChangeTime < ActiveRecord::Migration
  def up
    add_column :workers, :last_state_change_time, :timestamp
  end

  def down
    remove_column :workers, :last_state_change_time
  end
end
