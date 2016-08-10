class ProductCategory < ActiveRecord::Base
	belongs_to :product
	belongs_to :category

	def insert(product_id, product_categories)

		product_categories.each do |pc|
			
			time = Time.now.to_s(:db)

			product_category = "('#{product_id}', '#{pc}', '#{time}', '#{time}')"
			product_category_sql = "INSERT INTO product_categories (product_id, category_id,\
			created_at, updated_at) VALUES #{product_category}"

			ActiveRecord::Base.connection.execute(product_category_sql)				
		end
	end

	def delete(product_id)
		sql = "DELETE FROM product_categories WHERE product_id = '#{product_id}'"
		ActiveRecord::Base.connection.execute(sql)
	end

end
