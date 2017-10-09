class CreateWarehouseExaminings < ActiveRecord::Migration
  def change
    create_table :warehouse_examinings do |t|
      t.string :product_name, :country
      t.integer :product_no_ws_id
      t.integer :current_dm, :current_vc, :current_retail, :current_ws, :current_total,\
        :allocation, :on_order, :current_stock
      t.integer :count_dm, :count_vc, :count_retail, :count_ws, :count_total,\
        :count_size, :count_pack, :count_loose, :count_sample
      t.integer :difference
      t.integer :count_staff_id, :authorised_staff_id
      t.datetime :count_date, :authorised_date

      t.timestamps null: false
    end
  end
end
