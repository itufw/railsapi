class CreateFastwayConsignmentItems < ActiveRecord::Migration
  def change
    create_table :fastway_consignment_items, :id => false do |t|
      t.integer :ItemID, primary: true, null: false, index: true
      t.string :Reference
      t.integer :Packaging, :Weight, :WeightCubic
      t.datetime :CreateDate, :PrintDate
      t.integer :ExcessLabelCount
      t.string :LabelColour, :LabelNumber
      t.integer :ConsignmentID
      t.timestamps null: false
    end
  end
end
