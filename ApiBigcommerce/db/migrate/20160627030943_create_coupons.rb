class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|

      t.text :name, :code, limit: 255, null: false, unique: true

      t.timestamps null: false
    end
  end
end
