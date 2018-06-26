class AddTypeToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :type, :string, limit: 3
  end
end
