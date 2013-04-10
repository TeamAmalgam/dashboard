class CreateWorkers < ActiveRecord::Migration
  def up
    create_table :workers do |t|
      t.string :hostname
      t.timestamp :last_heartbeat
      t.integer :test_result_id
    end
  end

  def down
    drop_table :workers
  end
end
