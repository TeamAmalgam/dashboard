class CreateModels < ActiveRecord::Migration
  def up
    create_table :models do |t|
      t.string :filepath
      t.string :s3_key
    end
  end

  def down
    drop_table :models
  end
end
