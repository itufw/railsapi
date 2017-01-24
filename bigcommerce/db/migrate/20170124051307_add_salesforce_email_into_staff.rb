class AddSalesforceEmailIntoStaff < ActiveRecord::Migration
  def change
    remove_column :staffs, :contact_email
    remove_column :staffs, :contact_phone

    add_column :staffs, :salesforce_email, :string, index: true
  end
end
