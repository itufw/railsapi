class CreateDefaultAveragePeriods < ActiveRecord::Migration
  def change
    create_table :default_average_periods do |t|

      t.integer :staff_id
      t.string :name
      t.integer :days
      t.timestamps null: false
    end
  end
end
