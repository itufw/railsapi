class OrderAccountType < ActiveRecord::Migration
  def change
    add_column :customers, :account_type, :string
    add_column :customers, :payment_method, :string
    add_column :customers, :default_courier, :string
  end
end
