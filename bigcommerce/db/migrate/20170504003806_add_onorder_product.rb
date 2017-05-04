class AddOnorderProduct < ActiveRecord::Migration
  def change
    add_column :products, :on_order, :integer, limit: 1
  end
end
