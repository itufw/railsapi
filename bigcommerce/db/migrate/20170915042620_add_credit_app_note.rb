class AddCreditAppNote < ActiveRecord::Migration
  def change
    add_column :customer_credit_apps, :note, :text
  end
end
