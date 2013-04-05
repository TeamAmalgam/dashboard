class CreateTestResults < ActiveRecord::Migration
  def up
    create_table :test_results do |t|
      t.integer   :model_id
      t.integer   :type
      t.timestamp :time
      t.boolean   :completed
      t.boolean   :correct
      t.integer   :return_code
      t.string    :tarball_s3_key
      t.integer   :runtime_seconds
      t.integer   :secret_key
    end
  end

  def down
    drop_table :test_results
  end
end
