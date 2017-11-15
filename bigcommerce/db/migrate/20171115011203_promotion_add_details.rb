class PromotionAddDetails < ActiveRecord::Migration
  def change
    add_column :promotions, :rate, :integer
    add_column :promotions, :description, :text
  end
end
