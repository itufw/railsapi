class CreateFastwayManifests < ActiveRecord::Migration
  def change
    create_table :fastway_manifests, :id => false do |t|
      t.integer :ManifestID, primary: true, null: false, index: true
      t.string :Description
      t.integer :AutoImport
      t.datetime :AutoImportCompleteDate
      t.integer :MultiBusinessID
      t.datetime :CreateDate, :CloseDate
      t.timestamps null: false
    end
  end
end
