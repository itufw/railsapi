class AddProductNoWsSize < ActiveRecord::Migration
  def change
    add_column :product_no_ws, :case_size, :integer
  end
end
