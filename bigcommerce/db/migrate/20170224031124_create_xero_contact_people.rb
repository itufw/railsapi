class CreateXeroContactPeople < ActiveRecord::Migration
  def change

    create_table :xero_contact_people do |t|
      t.string :xero_contact_id, limit: 36, null: false, index: true
      t.string :customer_id, limit: 8, null: false, index: true
      t.string  :first_name
      t.string  :last_name
      t.string  :email_address
      t.boolean :include_in_emails

      t.timestamps null: false
    end
  end
end
