class ProductNoteLog < ActiveRecord::Migration
  def change
    add_column :product_notes, :version, :integer
  end
end
