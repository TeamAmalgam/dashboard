class AddCiEnabledToModels < ActiveRecord::Migration
  def up
    add_column :models, :ci_enabled, :boolean, :null => false, :default => false
  end

  def down
    remove_column :models, :ci_enabled
  end
end
