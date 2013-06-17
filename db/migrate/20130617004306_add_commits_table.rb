class AddCommitsTable < ActiveRecord::Migration
  class Repo < ActiveRecord::Base
    acts_as_singleton
  end

  class TestResult < ActiveRecord::Base
  end

  class Commit < ActiveRecord::Base
  end

  def up
    create_table :commits do |t|
      t.string :sha2_hash, :null => false
      t.timestamp :time, :null => false
    end

    add_column :repos, :commit_id, :integer

    repo = Repo.instance
    unless repo.head.nil?
      commit = Commit.create!(:sha2_hash => repo.head,
                              :time => repo.updated_at)
      repo.commit_id = commit.id
      repo.save!
    end

    add_column :test_results, :commit_id, :integer

    TestResult.order(:requested_at).where('commit IS NOT NULL').all.each do |test_result|
      commit = Commit.where(:sha2_hash => test_result.commit).first
      if commit.nil?
        commit = Commit.create!(:sha2_hash => test_result.commit,
                                :time => test_result.requested_at)
      end
      test_result.commit_id = commit.id
      test_result.save!
    end
  end

  def down
    remove_column :repos, :commit_id
    remove_column :test_results, :commit_id
    drop_table :commits
  end
end
