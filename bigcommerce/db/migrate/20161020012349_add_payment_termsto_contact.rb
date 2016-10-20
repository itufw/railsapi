class AddPaymentTermstoContact < ActiveRecord::Migration
  def change
  	add_column :customers, :num_days, :integer
  	add_column :customers, :end_of_month, :integer
  end
end
