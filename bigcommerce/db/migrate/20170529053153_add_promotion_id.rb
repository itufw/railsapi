class AddPromotionId < ActiveRecord::Migration
  def change
    add_column :tasks, :promotion_id, :integer

  end
end
