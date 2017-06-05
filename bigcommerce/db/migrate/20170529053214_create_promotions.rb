class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.string :name
      t.datetime :date_start, :date_end
      t.timestamps null: false
    end
  end
end
