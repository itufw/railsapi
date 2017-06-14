class CreateStaffDailySamples < ActiveRecord::Migration
  def change
    create_table :staff_daily_samples, id: false do |t|
      t.integer :staff_id, :product_id
      t.date :date
      t.timestamps null: false
    end
  end
end
