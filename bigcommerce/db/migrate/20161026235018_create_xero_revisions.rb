class CreateXeroRevisions < ActiveRecord::Migration
  def change
    create_table :xero_revisions do |t|
      t.datetime :last_update_time

      t.timestamps null: false
    end
  end
end
