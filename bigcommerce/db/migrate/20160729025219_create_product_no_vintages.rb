class CreateProductNoVintages < ActiveRecord::Migration
  def change
    create_table :product_no_vintages do |t|
      t.string :name

      t.timestamps null: false
    end

    add_column :products, :product_no_vintage_id, :integer, index: true
  end
end
