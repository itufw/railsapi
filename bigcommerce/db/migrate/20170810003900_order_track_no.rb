class OrderTrackNo < ActiveRecord::Migration
  def change
    add_column :orders, :track_number, :string
  end
end
