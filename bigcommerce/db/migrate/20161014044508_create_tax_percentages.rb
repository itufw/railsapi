class CreateTaxPercentages < ActiveRecord::Migration
  def change
    create_table :tax_percentages do |t|
      t.string :tax_name
      t.decimal :tax_percentage, precision: 8, scale: 2

      t.timestamps null: false
    end
  end
end
