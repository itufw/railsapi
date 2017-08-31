class OrderStreet2 < ActiveRecord::Migration
  def change
    add_column :customers, :street_2, :string
  end
end
