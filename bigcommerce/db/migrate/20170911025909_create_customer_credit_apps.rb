class CreateCustomerCreditApps < ActiveRecord::Migration
  def change
    create_table :customer_credit_apps do |t|
      t.integer :customer_id, :credit_application_version, index: true

      t.datetime :date_signed

      t.integer :director_signed

      t.text :company_name, :trading_name, :abn, limit: 200

      t.integer :abn_checked, :abn_checked_staff_id

      t.text :liquor_license_number, limit: 50

      t.integer :liquor_license_checked, :liquor_license_checked_staff_id

      t.text :address, :street, :street_2, :city, :state, :postcode, :phone, :fax

      t.datetime :business_commenced
      t.string :current_premises
      t.datetime :date_occupied
      # Direct Debit, Credit Card, EFT, Cheque, COD, CC surcharge
      t.string :payment_method_credit_app
      # defaults to the above but records change in the future
      t.string :payment_method
      t.datetime :payment_method_updated_date
      # End of Month, Net Invoice Date (default), COD, I2I
      t.string :credit_terms
      t.integer :credit_days, :tolerance_days
      t.string :credit_app_doc_id
      t.integer :credit_limit, :reference_check
      t.datetime :approved_date
      t.integer :approved_by, :staff_id
      t.timestamps null: false
    end
  end
end
