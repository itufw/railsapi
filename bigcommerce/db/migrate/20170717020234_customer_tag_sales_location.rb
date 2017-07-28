class CustomerTagSalesLocation < ActiveRecord::Migration
  def change
    add_column :customer_tags, :sales, :string
    add_column :customer_tags, :address, :string
    add_column :customer_tags, :state, :string
  end
end
