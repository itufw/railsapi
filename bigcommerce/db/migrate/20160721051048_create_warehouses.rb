class CreateWarehouses < ActiveRecord::Migration
  def change
    create_table :warehouses do |t|

      t.string :name

      t.timestamps null: false
    end
  end
end
