class CreateGoogleRevisions < ActiveRecord::Migration
  def change
    create_table :google_revisions do |t|
      t.datetime :start_time, :end_time
      t.timestamps null: false
    end
  end
end
