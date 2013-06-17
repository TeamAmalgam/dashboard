class RemoveCommitHashesFromTestResultsAndRepos < ActiveRecord::Migration
  class Repo < ActiveRecord::Base
    acts_as_singleton
  end

  class Commit < ActiveRecord::Base
  end

  class TestResult < ActiveRecord::Base
  end

  def up
    remove_column :repos, :head
    remove_column :test_results, :commit
  end

  def down
    add_column :repos, :head, :string
    repo = Repo.instance
    unless repo.commit_id.nil?
      repo_commit = Commit.where(:id => repo.commit_id).first
      repo.head = repo_commit.sha2_hash
      repo.save!
    end

    add_column :test_results, :commit, :string
    TestResult.where('commit_id IS NOT NULL').all.each do |test_result|
      commit = Commit.where(:id => test_result.commit_id).first
      test_result.commit = commit.sha2_hash
      test_result.save!
    end
  end
end
