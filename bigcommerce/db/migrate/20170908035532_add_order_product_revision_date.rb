class AddOrderProductRevisionDate < ActiveRecord::Migration
  def change
    add_column :order_products, :revision_date, :datetime
  end
end
