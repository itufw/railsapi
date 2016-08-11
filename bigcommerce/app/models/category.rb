# helper classes
require 'bigcommerce_connection.rb'
require 'clean_data.rb'


class Category < ActiveRecord::Base
	has_many :product_categories
	has_many :products, through: :product_categories

	has_one :parent, class_name: :Category, foreign_key: :parent_id
	belongs_to :child, class_name: :Category, foreign_key: :parent_id

	# Mass insert data from Bigcommerce API
	def scrape

		category_api = Bigcommerce::Category
		category_count = category_api.count.count

		# Bigcommerce API only get 50 items per page
		limit = 50

		category_pages = (category_count/limit) + 1

		page_number = 1

		# Loop through all pages
		category_pages.times do

			categories = category_api.all(page: page_number)

			categories.each do |c|
	
				insert_sql(c, 1)
				
			end

			page_number += 1

		end

	end

	# Form and execute insert/update sql statements
	def insert_sql(c, insert)

		time = Time.now.to_s(:db)

		clean = CleanData.new

		visible = clean.convert_bool(c.is_visible)
		description = clean.remove_apostrophe(c.description)
		name = clean.remove_apostrophe(c.name)
		description = ActionView::Base.full_sanitizer.sanitize(description)
		meta_description = clean.remove_apostrophe(c.meta_description)

		sql = category = ""

		if insert == 1
			category =  "('#{c.id}', '#{c.parent_id}', '#{name}', '#{description}', '#{c.sort_order}',\
			'#{c.page_title}', '#{c.meta_keywords}', '#{meta_description}', '#{c.search_keywords}', '#{c.url}',\
			'#{visible}', '#{time}', '#{time}')"

			sql = "INSERT INTO categories(id, parent_id, name, description, sort_order, page_title, meta_keywords,\
			meta_description, search_keywords, url, visible, created_at, updated_at) VALUES #{category}"
		else

			sql = "UPDATE categories SET parent_id = '#{c.parent_id}', name = '#{name}', description = '#{description}',\
			sort_order = '#{c.sort_order}', page_title = '#{c.page_title}', meta_keywords = '#{c.meta_keywords}', meta_description = '#{meta_description}',\
			search_keywords = '#{c.search_keywords}', url = '#{c.url}', visible = '#{visible}', updated_at = '#{time}'\
			WHERE id = '#{c.id}'"

			
		end

		ActiveRecord::Base.connection.execute(sql) 

	end

	# update items
	def update_from_api(update_time)
		category_api = Bigcommerce::Category

		category_count = category_api.count.count
		limit = 50
		category_pages = (category_count/limit) + 1

		page_number = 1

		category_pages.times do 

			
			categories = category_api.all(page: page_number)

			if categories.blank?
				return
			end

			categories.each do |c|

				# if it exists - then update
				if !Category.where(id: c.id).blank?
					insert_sql(c, 0)

				# otherwise insert
				else

					insert_sql(c, 1)

				end

			end
			page_number += 1
			
		end

	end
end
