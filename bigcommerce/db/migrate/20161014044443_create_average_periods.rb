class CreateAveragePeriods < ActiveRecord::Migration
  def change
    create_table :average_periods do |t|
      t.string :name
      t.integer :days

      t.timestamps null: false
    end
  end
end
