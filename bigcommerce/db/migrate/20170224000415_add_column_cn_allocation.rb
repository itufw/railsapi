class AddColumnCnAllocation < ActiveRecord::Migration
  def change
    add_column :xero_cn_allocations, :status, :string
    add_column :xero_cn_allocations, :credit_note_number, :string
    add_column :xero_cn_allocations, :reference, :string
  end
end
