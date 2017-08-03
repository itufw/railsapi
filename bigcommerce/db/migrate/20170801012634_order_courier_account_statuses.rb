class OrderCourierAccountStatuses < ActiveRecord::Migration
  def change
    add_column :orders, :courier_status_id, :integer
    add_column :orders, :account_status, :string
  end
end
