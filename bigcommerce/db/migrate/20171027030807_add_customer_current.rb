class AddCustomerCurrent < ActiveRecord::Migration
  def change
    add_column :customers, :current, :integer
    add_column :customers, :priority, :integer
  end
end
