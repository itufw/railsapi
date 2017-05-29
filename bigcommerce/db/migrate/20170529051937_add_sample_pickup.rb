class AddSamplePickup < ActiveRecord::Migration
  def change
    add_column :staffs, :pick_up_id, :integer

  end
end
