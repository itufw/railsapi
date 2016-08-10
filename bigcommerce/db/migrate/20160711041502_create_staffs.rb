class CreateStaffs < ActiveRecord::Migration
  def change
    create_table :staffs do |t|

      t.string :firstname
      t.string :lastname
      t.string :nickname
      t.string :email
      t.string :logon_details
      t.string :contact_number
      t.string :state
      t.string :country
      t.string :user_type
      t.integer :display_report, limit: 1, index: true
      t.integer :invoice_rights, limit: 1, index: true
      t.integer :product_rights, limit: 1, index: true
      t.integer :payment_rights, limit: 1, index: true
      t.integer :active, limit: 1, index: true
      t.string :password_digest

      t.timestamps null: false
    end
  end
end
