require 'bigcommerce_connection.rb'
require 'clean_data.rb'

class Product < ActiveRecord::Base
	has_many :order_products
	has_many :orders, through: :order_products

	has_many :product_categories
	has_many :categories, through: :product_categories

	belongs_to :product_type
	belongs_to :product_sub_type
	belongs_to :product_size
	belongs_to :warehouse
	belongs_to :product_package_type
	belongs_to :producer
	belongs_to :producer_country
	belongs_to :producer_region
	belongs_to :product_no_vintage

	scoped_search on: [:name, :portfolio_region]

	def scrape

		product_api = Bigcommerce::Product
		product_count = product_api.count.count
		limit = 50

		product_pages = (product_count/limit) + 1
		
		page_number = 1

		product_pages.times do

			products = product_api.all(page: page_number)

			products.each do |p|
				
				insert_sql(p, 1)
				ProductCategory.new.insert(p.id, p.categories)

			end

			page_number += 1

		end

	end


	def insert_sql(p, insert)
		time = Time.now.to_s(:db)
		clean = CleanData.new
		date_created = clean.map_date(p.date_created)
		date_modified = clean.map_date(p.date_modified)
		date_last_imported = clean.map_date(p.date_last_imported)

		visible = clean.convert_bool(p.is_visible)
		featured = clean.convert_bool(p.is_featured)

		name = clean.remove_apostrophe(p.name)
		search_keywords = clean.remove_apostrophe(p.search_keywords)
		meta_keywords = clean.remove_apostrophe(p.meta_keywords)
		description = ActionView::Base.full_sanitizer.sanitize(clean.remove_apostrophe(p.description))
		meta_description = clean.remove_apostrophe(p.meta_description)
		page_title = clean.remove_apostrophe(p.page_title)

		if p.sku == ''
			sku = 0
		else
			sku = p.sku
		end

		sql = ""
		product = ""

		if insert == 1
			product =  "('#{p.id}', '#{sku}', '#{name}', '#{p.inventory_level}', '#{date_created}',\
			'#{p.weight}', '#{p.height}', '#{p.width}', '#{visible}', #{featured}, '#{p.availability}',\
			'#{date_modified}', '#{date_last_imported}', '#{p.total_sold}', '#{p.view_count}',\
			'#{p.upc}', '#{p.bin_picking_number}', '#{search_keywords}', '#{meta_keywords}',\
			'#{description}', '#{meta_description}', '#{page_title}', '#{p.retail_price}',\
			'#{p.sale_price}', '#{p.calculated_price}', '#{p.inventory_warning_level}', '#{p.inventory_tracking}',\
			'#{p.keyword_filter}', '#{p.sort_order}', '#{p.related_products}', '#{p.rating_total}',\
			'#{p.rating_count}', '#{time}', '#{time}')"

			sql = "INSERT INTO products(id, sku, name, inventory, date_created, weight, height,\
			width, visible, featured, availability, date_modified, date_last_imported, num_sold, num_viewed,\
			upc, bin_picking_num, search_keywords, meta_keywords, description, meta_description,\
			page_title, retail_price, sale_price, calculated_price, inventory_warning_level, inventory_tracking,\
			keyword_filter, sort_order, related_products, rating_total, rating_count, created_at, updated_at)\
			VALUES #{product}"

		else

			# sql = "UPDATE products SET sku = '#{sku}', name = '#{name}', inventory = '#{p.inventory_level}',\
			# date_created = '#{date_created}', weight = '#{p.weight}', height = '#{p.height}', width = '#{p.width}',\
			# visible = '#{visible}', featured = '#{featured}', availability = '#{p.availability}', date_modified = '#{date_modified}',\
			# date_last_imported = '#{date_last_imported}', num_sold = '#{p.total_sold}', num_viewed = '#{p.view_count}',\
			# upc = '#{p.upc}', bin_picking_num = '#{p.bin_picking_number}', search_keywords = '#{search_keywords}', meta_keywords = '#{meta_keywords}',\
			# description = '#{description}', meta_description = '#{meta_description}', page_title = '#{page_title}', retail_price = '#{p.retail_price}',\
			# sale_price = '#{p.sale_price}', calculated_price = '#{p.calculated_price}', inventory_warning_level = '#{p.inventory_warning_level}',\
			# inventory_tracking = '#{p.inventory_tracking}', keyword_filter = '#{p.keyword_filter}', sort_order = '#{p.sort_order}',\
			# related_products = '#{p.related_products}', rating_total = '#{p.rating_total}', rating_count = '#{p.rating_count}', updated_at = '#{time}'\
			# WHERE id = '#{p.id}'"

			sql = "UPDATE products SET inventory = '#{p.inventory_level}' WHERE id = '#{p.id}'"

		end

		ActiveRecord::Base.connection.execute(sql)

	end

	def update_from_api(update_time)

		product_api = Bigcommerce::Product
		product_count = product_api.count(min_date_modified: update_time).count
		limit = 50
		product_pages = (product_count/limit) + 1

		page_number = 1

		product_pages.times do 
			
			products = product_api.all(min_date_modified: update_time, page: page_number)

			if products.blank?
				return
			end

			products.each do |p|

				

				if Product.where(id: p.id).count == 1
				
					insert_sql(p, 0)
				else
					insert_sql(p, 1)
				end

				#ProductCategory.new.delete(p.id)
				#ProductCategory.new.insert(p.id, p.categories)
			end

			page_number += 1
		end

	end


	def self.filter(search_text = nil, country_id = nil, sub_type_id = nil)
		return where(producer_country_id: country_id, product_sub_type_id: sub_type_id).search_for(search_text) if country_id && sub_type_id
		return where(producer_country_id: country_id).search_for(search_text) if country_id
		return where(product_sub_type_id: sub_type_id).search_for(search_text) if sub_type_id
		all.search_for(search_text)
	end


end
