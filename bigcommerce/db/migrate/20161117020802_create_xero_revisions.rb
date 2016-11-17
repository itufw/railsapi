class CreateXeroRevisions < ActiveRecord::Migration
  def change
    create_table :xero_revisions do |t|
    end
  end
end

class CreateXeroRevisions < ActiveRecord::Migration
  def change
    create_table :xero_revisions do |t|
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps null: false
    end
  end
end
