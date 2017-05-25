class TaskPromotionPortfolio < ActiveRecord::Migration
  def change
    add_column :tasks, :portfolio_id, :integer

  end
end
