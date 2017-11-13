class AddOrderScotPacLoaded < ActiveRecord::Migration
  def change
    add_column :orders, :scot_pac_load, :integer
  end
end
