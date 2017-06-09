class CreateCustContacts < ActiveRecord::Migration
  def change
    create_table :cust_contacts do |t|
      t.integer :customer_id, :contact_id
      t.string :position, :title, :phone, :fax, :email
      t.integer :c_receive_invoice
      t.timestamps null: false
    end
  end
end
