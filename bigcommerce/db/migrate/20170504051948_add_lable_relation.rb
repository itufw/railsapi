class AddLableRelation < ActiveRecord::Migration
  def change
    add_column :product_lable_relations, :number, :integer
  end
end
