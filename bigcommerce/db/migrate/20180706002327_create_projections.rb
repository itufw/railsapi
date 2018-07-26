class CreateProjections < ActiveRecord::Migration
  def change
    create_table :projections do |t|
      t.integer :customer_id,   null: false
      t.string :customer_name,  limit: 120
      t.integer :q_lines,       limit: 1
      t.integer :q_bottles,     limit: 2
      t.float :q_avgluc
      t.string :quarter,        limit: 6
      t.boolean :recent
      t.integer :created_by_id, null: false
      t.string :created_by_name,     limit: 50
      t.string :sale_rep_name, limit: 50
      t.integer :sale_rep_id

      t.timestamps null: false
    end
  end
end
