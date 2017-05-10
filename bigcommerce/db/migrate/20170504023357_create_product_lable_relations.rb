# connect lable and products
class CreateProductLableRelations < ActiveRecord::Migration
  def change
    create_table :product_lable_relations do |t|
      t.integer :product_id, :product_lable_id
      t.timestamps null: false
    end
  end
end
