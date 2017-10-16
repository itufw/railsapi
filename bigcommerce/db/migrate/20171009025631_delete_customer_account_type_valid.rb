class DeleteCustomerAccountTypeValid < ActiveRecord::Migration
  def change
    remove_column :customer_account_types, :valid
  end
end
