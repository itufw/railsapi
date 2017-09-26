class AddOrderProductHistoryRevision < ActiveRecord::Migration
  def change
    add_column :order_product_histories, :revision_date, :datetime
  end
end
