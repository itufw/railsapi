class CreateProductNotes < ActiveRecord::Migration
  def change
    create_table :product_notes do |t|
      t.integer :task_id, :created_by, :product_id, :rating
      t.text :note
      t.string :intention
      t.decimal :price, :price_luc, scale: 3, precision: 7
      t.timestamps null: false
    end
  end
end
