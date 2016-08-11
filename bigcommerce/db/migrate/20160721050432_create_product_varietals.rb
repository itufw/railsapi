class CreateProductVarietals < ActiveRecord::Migration
  def change
    create_table :product_varietals do |t|

      t.string :name
      t.integer :product_type_id

      t.timestamps null: false
    end
  end
end
