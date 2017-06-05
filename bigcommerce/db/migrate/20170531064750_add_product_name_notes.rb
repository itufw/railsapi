class AddProductNameNotes < ActiveRecord::Migration
  def change
    add_column :product_notes, :product_name, :string
  end
end
