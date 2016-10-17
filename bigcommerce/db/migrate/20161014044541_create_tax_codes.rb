class CreateTaxCodes < ActiveRecord::Migration
  def change
    create_table :tax_codes do |t|
      t.string :customer_type
      t.string :tax_code

      t.timestamps null: false
    end
  end
end
