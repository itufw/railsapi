class CreatePortfolios < ActiveRecord::Migration
  def change
    create_table :portfolios do |t|
      t.datetime :date_start, :date_end
      t.text :name, :pipe
      t.timestamps null: false
    end
  end
end
