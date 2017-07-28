class CreateFastwayConsignments < ActiveRecord::Migration
  def change
    create_table :fastway_consignments, :id => false do |t|
      t.integer :ConsignmentID, primary: true, null: false, index: true
      t.integer :AccountNumber
      t.string :CompanyName, :Address1, :Address2, :City, :PostCode
      t.string :SpecialInstruction1, :SpecialInstruction2, :SpecialInstruction3
      t.string :ContactEmail, :ContactPhone, :ContactMobile, :ContactName, :DestinationFranchise, :ThirdPartyConsignmentID
      t.string :SenderFirstName, :SenderLastName, :SenderContactNumber
      t.datetime :CreateDate
      t.integer :NotificationEmailSent
      t.integer :ManifestID
      t.timestamps null: false
    end
  end
end
