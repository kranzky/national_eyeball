class AddSpatialFeatures < ActiveRecord::Migration
  def change
    create_table :features do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.float :lat, null: false
      t.float :lng, null: false
      t.integer :postcode
      t.float :area
      t.text :polyline
    end
    add_index :features, :type
    add_index :features, :lat
    add_index :features, :lng
  end
end
