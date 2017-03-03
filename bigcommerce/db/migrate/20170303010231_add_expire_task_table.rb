class AddExpireTaskTable < ActiveRecord::Migration
  def change
    add_column :tasks, :expired, :integer, limit: 1
  end
end
