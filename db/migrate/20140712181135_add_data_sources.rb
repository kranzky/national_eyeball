class AddDataSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :description, null: false
    end
  end
end
