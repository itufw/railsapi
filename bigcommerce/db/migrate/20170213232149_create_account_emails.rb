class CreateAccountEmails < ActiveRecord::Migration
  def change
    create_table :account_emails do |t|
      t.string :receive_address, :send_address
      t.text :content
      t.string :email_type, :selected_invoices
      t.integer :customer_id

      t.timestamps null: false
    end
  end
end
