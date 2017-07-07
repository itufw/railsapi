class ProductNoteTasteFlag < ActiveRecord::Migration
  def change
    add_column :product_notes, :tasted, :integer
  end
end
