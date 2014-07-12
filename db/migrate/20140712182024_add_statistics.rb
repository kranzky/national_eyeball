class AddStatistics < ActiveRecord::Migration
  def change
    create_table :statistics do |t|
      t.integer :source_id, null: false
      t.integer :parent_id
      t.string :name, null: false
      t.string :feature_type, null: false
    end
    add_index :statistics, :source_id
    add_index :statistics, :parent_id
  end
end
