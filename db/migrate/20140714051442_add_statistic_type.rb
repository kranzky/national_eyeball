class AddStatisticType < ActiveRecord::Migration
  def change
    add_column :statistics, :type, :string
    add_index :statistics, :type
  end
end
