class CustomerToleranceDay < ActiveRecord::Migration
  def change
    add_column :customers, :tolerance_day, :integer
  end
end
