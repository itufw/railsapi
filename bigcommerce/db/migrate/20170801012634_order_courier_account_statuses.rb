class OrderCourierAccountStatuses < ActiveRecord::Migration
  def change
    add_column :orders, :courier_status_id, :integer
    add_column :orders, :account_status, :string
    add_column :orders, :street, :text
    add_column :orders, :city, :string
    add_column :orders, :state, :string
    add_column :orders, :postcode, :string
    add_column :orders, :country, :string
    add_column :orders, :address, :string
    add_column :orders, :track_number, :string
    add_column :orders, :modified_wet, :float
    add_column :orders, :billing_address, :string
    add_column :orders, :delivery_instruction, :text
  end
end
