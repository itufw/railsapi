class CreateSaleRateTerms < ActiveRecord::Migration
  def change
    create_table :sale_rate_terms do |t|
      t.string :name
      t.integer :days_from, :days_until, :weight, :term
      t.timestamps null: false
    end
  end
end
