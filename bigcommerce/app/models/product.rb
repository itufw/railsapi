require 'bigcommerce_connection.rb'
require 'clean_data.rb'
require 'application_helper.rb'

class Product < ActiveRecord::Base

	include CleanData
	include ApplicationHelper

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

	self.per_page = 30

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

		date_created = map_date(p.date_created)
		date_modified = map_date(p.date_modified)
		date_last_imported = map_date(p.date_last_imported)

		visible = convert_bool(p.is_visible)
		featured = convert_bool(p.is_featured)

		name = remove_apostrophe(p.name)
		search_keywords = remove_apostrophe(p.search_keywords)
		meta_keywords = remove_apostrophe(p.meta_keywords)
		description = ActionView::Base.full_sanitizer.sanitize(remove_apostrophe(p.description))
		meta_description = remove_apostrophe(p.meta_description)
		page_title = remove_apostrophe(p.page_title)

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

			sql = "UPDATE products SET sku = '#{sku}', name = '#{name}', inventory = '#{p.inventory_level}',\
			date_created = '#{date_created}', weight = '#{p.weight}', height = '#{p.height}', width = '#{p.width}',\
			visible = '#{visible}', featured = '#{featured}', availability = '#{p.availability}', date_modified = '#{date_modified}',\
			date_last_imported = '#{date_last_imported}', num_sold = '#{p.total_sold}', num_viewed = '#{p.view_count}',\
			upc = '#{p.upc}', bin_picking_num = '#{p.bin_picking_number}', search_keywords = '#{search_keywords}', meta_keywords = '#{meta_keywords}',\
			description = '#{description}', meta_description = '#{meta_description}', page_title = '#{page_title}', retail_price = '#{p.retail_price}',\
			sale_price = '#{p.sale_price}', calculated_price = '#{p.calculated_price}', inventory_warning_level = '#{p.inventory_warning_level}',\
			inventory_tracking = '#{p.inventory_tracking}', keyword_filter = '#{p.keyword_filter}', sort_order = '#{p.sort_order}',\
			related_products = '#{p.related_products}', rating_total = '#{p.rating_total}', rating_count = '#{p.rating_count}', updated_at = '#{time}'\
			WHERE id = '#{p.id}'"

			#sql = "UPDATE products SET inventory = '#{p.inventory_level}' WHERE id = '#{p.id}'"

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

	def self.producer_country_filter(producer_country_id)
		return where(producer_country_id: producer_country_id) if producer_country_id
		return all
	end

	def self.sub_type_filter(product_sub_type_id)
		return where(product_sub_type_id: product_sub_type_id) if product_sub_type_id
		return all
	end

	def self.producer_filter(producer_id)
		return where(producer_id: producer_id) if producer_id
		return all
	end

	def self.producer_region_filter(producer_region_id)
		return where(producer_region_id: producer_region_id) if producer_region_id
		return all
	end

	def self.type_filter(type_id)
		return where(product_type_id: type_id) if type_id
		return all
	end


	def self.search(search_text)
		return search_for(search_text)
	end

	def self.filter_by_ids(product_ids_a)
		if (product_ids_a.empty? || product_ids_a.nil?)
			return all
		end
	    return where('products.id IN (?)', product_ids_a)
	end

	def self.filter_by_ids_nil_allowed(product_ids_a)
	    return where('products.id IN (?)', product_ids_a)
	end

	def self.include_orders
		includes([{:order_products => :order}])
	end

	def self.pending_stock(group_by)
		include_orders.where('orders.status_id = 1').references(:orders).group(group_by).sum('order_products.qty')
	end

	def self.order_by_name(direction)
		order('name ' + direction)
	end

	def self.order_by_id(direction)
		order('id ' + direction)
	end

	def ex_gst_price
		if self.retail_ws == 'WS'
	      return self.calculated_price * 1.29
	    else
	      return self.calculated_price
	    end
	end

	def self.order_by_price(direction)
		if direction == 'ASC'
			return Product.all.sort_by(&:ex_gst_price)
		else
			return Product.all.sort_by(&:ex_gst_price).reverse
		end
	end

	def self.order_by_stock(direction)
		order('inventory ' + direction)
	end

	def self.no_vintage_id(product_id)
		return find(product_id).product_no_vintage_id
	end

	def self.no_ws_id(product_id)
		return find(product_id).product_no_ws_id
	end

	def self.products_with_same_no_vintage_id(no_vintage_id)
		return where(product_no_vintage_id: no_vintage_id)
	end

	def self.products_with_same_no_ws_id(no_ws_id)
		return where(product_no_ws_id: no_ws_id)
	end

	def self.group_by_product_no_vintage_id
		group(:product_no_vintage_id)
	end

	def self.group_by_product_no_ws_id
		group(:product_no_ws_id)
	end


	# transform column is no_vintage_id, no_ws_id
	def self.product_price(transform_column)
		if transform_column == 'group_by_id'
			pluck("id, calculated_price").to_h
		else
			send(transform_column).average(:calculated_price).merge\
			(self.where(retail_ws: 'WS').send(transform_column).average(:calculated_price))
		end
	end

end
