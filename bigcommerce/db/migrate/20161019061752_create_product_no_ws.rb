class CreateProductNoWs < ActiveRecord::Migration
  def change
    create_table :product_no_ws do |t|
      t.string :name
      t.integer :product_no_vintage_id, index: true

      t.timestamps null: false
    end
  end
end
