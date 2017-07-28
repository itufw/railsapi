class OrderSourceShippingId < ActiveRecord::Migration
  def change
    add_column :orders, :source, :string
    add_column :orders, :source_id, :integer
    add_column :orders, :shipping_status_id, :integer
  end
end
