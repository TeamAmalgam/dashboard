class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :return_code
      t.timestamp :requested_at
      t.timestamp :start_time
      t.timestamp :complete_time
    end
  end
end
