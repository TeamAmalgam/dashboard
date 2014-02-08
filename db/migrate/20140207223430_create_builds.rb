class CreateBuilds < ActiveRecord::Migration
  def change
    create_table :builds do |t|
      t.integer :commit_id
      t.integer :job_id
      t.string  :jar_s3_key
      t.timestamp :requested_at
    end
  end
end
