class CreateFastwayTraces < ActiveRecord::Migration
  def change
    create_table :fastway_traces do |t|
      t.string :LabelNumber, :Type, :Courier, :Description
      t.datetime :Date, :UploadDate
      t.string :Name, :Status, :Franchise, :StatusDescription
      t.string :contactName, :company, :address1, :address2, :address3, :address4, :address5, :address6, :address7, :address8, :comment
      t.string :Signature, :DistributedTo, :ParcelConnectAgent, :Reference
      t.timestamps null: false
    end
  end
end
