class AddProdRefColumnsToProduct < ActiveRecord::Migration
  def change
  	add_column :products, :name_no_ws, :string
  	add_column :products, :name_no_winery, :string
  	add_column :products, :name_no_vintage, :string
  	add_column :products, :name_no_winery_no_vintage, :string
  	add_column :products, :portfolio_name, :string
  	add_column :products, :current, :integer, limit: 1
  	add_column :products, :display, :integer, limit: 1
  	add_column :products, :retail_ws, :string
  	add_column :products, :blend_type, :string
  	add_column :products, :vintage, :string
  	add_column :products, :order_1, :integer
  	add_column :products, :order_2, :integer
  	add_column :products, :combined_order, :decimal, scale: 2, precision: 6
  	add_column :products, :portfolio_region, :string
  	add_column :products, :case_size, :integer, limit: 2
  	add_column :products, :price_id, :string
  	add_column :products, :organic_cert, :integer, limit: 1
  	add_column :products, :organic_pract, :integer, limit: 1
  	add_column :products, :organic_min, :integer, limit: 1
  	add_column :products, :vegan, :integer, limit: 1
  	add_column :products, :vegetarian, :integer, limit: 1
  	add_column :products, :bio_cert, :integer, limit: 1
  	add_column :products, :bio_pract, :integer, limit: 1
  	add_column :products, :filtration, :integer, limit: 1
  	add_column :products, :fining, :integer, limit: 1
  	add_column :products, :so2, :integer, limit: 1

  end
end
