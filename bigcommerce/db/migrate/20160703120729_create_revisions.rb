class CreateRevisions < ActiveRecord::Migration
  def change
    create_table :revisions do |t|

      t.datetime :next_update_time
      t.text :notes
      t.timestamps null: false
    end
  end
end
