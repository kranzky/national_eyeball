class AddValues < ActiveRecord::Migration
  def change
    create_table :values do |t|
      t.integer :statistic_id, null: false 
      t.integer :feature_id, null: false 
      t.float :value, null: false
    end
    add_index :values, :statistic_id
    add_index :values, :feature_id
    add_index :values, :value
  end
end
