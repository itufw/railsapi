class CreateCustomerStates < ActiveRecord::Migration
  def change
    create_table :customer_states do |t|
      t.string :state
      t.string :state_full
      t.timestamps null: false
    end
  end
end
