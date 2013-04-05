class ChangeSecretKeyToVarchar < ActiveRecord::Migration
  def up
    change_column :test_results, :secret_key, :string
  end

  def down
    change_column :test_results, :secret_key, :integer
  end
end
