class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.text :text, null:true
      t.integer :priority
      t.string :status
      t.datetime :due_date

      t.integer :staff_id, :customer_id, null: false, unsigned: true, index: true

      t.timestamps null: false
    end
  end
end
