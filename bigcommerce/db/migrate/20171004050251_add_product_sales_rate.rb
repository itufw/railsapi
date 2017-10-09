class AddProductSalesRate < ActiveRecord::Migration
  def change
    add_column :products, :sale_term_1, :integer
    add_column :products, :sale_term_2, :integer
    add_column :products, :sale_term_3, :integer
    add_column :products, :sale_term_4, :integer
    add_column :products, :monthly_supply, :decimal, scale: 2, precision: 6
  end
end
