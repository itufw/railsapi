class CustomerOrderSpecialInstruction < ActiveRecord::Migration
  def change
    add_column :customers, :SpecialInstruction1, :string, limit: 50
    add_column :customers, :SpecialInstruction2, :string, limit: 50
    add_column :customers, :SpecialInstruction3, :string, limit: 50

    add_column :orders, :SpecialInstruction1, :string, limit: 50
    add_column :orders, :SpecialInstruction2, :string, limit: 50
    add_column :orders, :SpecialInstruction3, :string, limit: 50
  end
end
