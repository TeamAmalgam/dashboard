class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string    :type
      t.timestamp :requested_at
      t.timestamp :started_at
      t.timestamp :finished_at
      t.integer   :return_code

      t.string    :secret_key

      t.integer   :commit_id
      t.string    :result_s3_key

      # Test Run Specific Fields
      t.boolean   :correct
      t.integer   :test_type
      t.integer   :model_id
      t.integer   :cpu_time_seconds
      t.integer   :real_time_seconds
    end
  end
end
