class AddForeignKeys < ActiveRecord::Migration
  def change
  	# add_foreign_key :orders, :customers
  	# add_foreign_key :orders, :statuses
  	# add_foreign_key :orders, :staffs
  	# add_foreign_key :orders, :addresses, column: :billing_address_id, primary_key: :id
   #  add_foreign_key :orders, :coupons

   #  add_foreign_key :categories, :categories, column: :parent_id, primary_key: :id
    
   #  add_foreign_key :addresses, :customers

    #add_foreign_key :order_products, :orders
   #  add_foreign_key :order_products, :products
   #  add_foreign_key :order_products, :order_shippings

   #  add_foreign_key :product_categories, :products
   #  add_foreign_key :product_categories, :categories

   #  add_foreign_key :order_histories, :orders
   #  add_foreign_key :order_histories, :customers
  	# add_foreign_key :order_histories, :statuses
  	# add_foreign_key :order_histories, :staffs
  	# add_foreign_key :order_histories, :addresses, column: :billing_address_id, primary_key: :id
   #  add_foreign_key :order_histories, :coupons


    #add_foreign_key :order_product_histories, :order_histories
    #add_foreign_key :order_product_histories, :orders
   #  add_foreign_key :order_product_histories, :products
   #  add_foreign_key :order_product_histories, :order_shipping_histories

   #  add_foreign_key :order_shippings, :orders
   #  add_foreign_key :order_shippings, :addresses

   #  add_foreign_key :order_shipping_histories, :order_histories
   #  add_foreign_key :order_shipping_histories, :addresses
  end
end
