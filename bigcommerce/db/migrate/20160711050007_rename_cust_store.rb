class RenameCustStore < ActiveRecord::Migration
  def change
  	rename_table :cust_stores, :cust_styles
  end
end
