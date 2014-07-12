class AddDensities < ActiveRecord::Migration
  def change
    create_table :densities do |t|
      t.integer :statistic_id, null: false 
      t.integer :feature_id, null: false 
      t.float :density, null: false
    end
    add_index :densities, :statistic_id
    add_index :densities, :feature_id
    add_index :densities, :density
  end
end
