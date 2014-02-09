# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140209024553) do

  create_table "commits", :force => true do |t|
    t.string   "sha2_hash", :null => false
    t.datetime "time",      :null => false
    t.string   "comment"
  end

  create_table "jobs", :force => true do |t|
    t.string   "type"
    t.datetime "requested_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer  "return_code"
    t.string   "secret_key"
    t.integer  "commit_id"
    t.string   "result_s3_key"
    t.boolean  "correct"
    t.integer  "test_type"
    t.integer  "model_id"
    t.integer  "cpu_time_seconds"
    t.integer  "real_time_seconds"
  end

  create_table "models", :force => true do |t|
    t.string  "filepath"
    t.string  "s3_key"
    t.boolean "ci_enabled", :default => false, :null => false
  end

  create_table "repos", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "commit_id"
  end

  create_table "workers", :force => true do |t|
    t.string   "hostname"
    t.datetime "last_heartbeat"
    t.integer  "test_result_id"
    t.datetime "last_state_change_time"
  end

end
