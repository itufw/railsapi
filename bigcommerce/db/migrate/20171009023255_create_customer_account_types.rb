class CreateCustomerAccountTypes < ActiveRecord::Migration
  def change
    create_table :customer_account_types do |t|
      t.string :name, :status
      t.integer :alert, :valid

      t.timestamps null: false
    end
  end
end
