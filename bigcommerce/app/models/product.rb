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

  has_many :product_lable_relations
  has_many :product_lable, through: :product_lable_relations

  has_many :product_notes
  has_many :staff_daily_samples

  belongs_to :product_type
  belongs_to :product_sub_type
  belongs_to :product_size
  belongs_to :warehouse
  belongs_to :product_package_type
  belongs_to :producer
  belongs_to :producer_country
  belongs_to :producer_region
  belongs_to :product_no_vintage
  belongs_to :product_no_ws

  # DO NOT USE
  after_validation :bigcommerce_inventory_overwrite, on: [:update], if: -> (obj){ obj.id == 2233 and obj.inventory_changed?}

  scoped_search on: %i[id name portfolio_region]

  self.per_page = 30

  def scrape
    product_api = Bigcommerce::Product
    product_count = product_api.count.count
    limit = 50

    product_pages = (product_count / limit) + 1

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

    sku = if p.sku == ''
            0
          else
            p.sku
          end

    sql = ''
    product = ''

    if insert == 1
      product = "('#{p.id}', '#{sku}', '#{name}', '#{p.inventory_level}', '#{date_created}',\
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
      # Deleted Inventory level update
      sql = "UPDATE products SET sku = '#{sku}', name = '#{name}',\
			date_created = '#{date_created}', weight = '#{p.weight}', height = '#{p.height}', width = '#{p.width}',\
			visible = '#{visible}', featured = '#{featured}', availability = '#{p.availability}', date_modified = '#{date_modified}',\
			date_last_imported = '#{date_last_imported}', num_sold = '#{p.total_sold}', num_viewed = '#{p.view_count}',\
			upc = '#{p.upc}', bin_picking_num = '#{p.bin_picking_number}', search_keywords = '#{search_keywords}', meta_keywords = '#{meta_keywords}',\
			description = '#{description}', meta_description = '#{meta_description}', page_title = '#{page_title}', retail_price = '#{p.retail_price}',\
			sale_price = '#{p.sale_price}', calculated_price = '#{p.calculated_price}', inventory_warning_level = '#{p.inventory_warning_level}',\
      inventory = '#{p.inventory_level}',\
      inventory_tracking = '#{p.inventory_tracking}', keyword_filter = '#{p.keyword_filter}', sort_order = '#{p.sort_order}',\
			related_products = '#{p.related_products}', rating_total = '#{p.rating_total}', rating_count = '#{p.rating_count}', updated_at = '#{time}'\
			WHERE id = '#{p.id}'"

      # sql = "UPDATE products SET inventory = '#{p.inventory_level}' WHERE id = '#{p.id}'"

    end

    ActiveRecord::Base.connection.execute(sql)
  end

  def update_from_api(update_time)
    product_api = Bigcommerce::Product
    product_count = product_api.count(min_date_modified: update_time).count
    limit = 50
    product_pages = (product_count / limit) + 1

    page_number = 1

    product_pages.times do
      products = product_api.all(min_date_modified: update_time, page: page_number)

      return if products.blank?

      products.each do |p|
        if Product.where(id: p.id).count == 1

          insert_sql(p, 0)
        else
          insert_sql(p, 1)
        end

        # ProductCategory.new.delete(p.id)
        # ProductCategory.new.insert(p.id, p.categories)
      end

      page_number += 1
    end
  end

  def self.producer_country_filter(producer_country_id)
    return where(producer_country_id: producer_country_id) if producer_country_id
    all
  end

  def self.sub_type_filter(product_sub_type_id)
    return where(product_sub_type_id: product_sub_type_id) if product_sub_type_id
    all
  end

  def self.producer_filter(producer_id)
    return where(producer_id: producer_id) if producer_id
    all
  end

  def self.producer_region_filter(producer_region_id)
    return where(producer_region_id: producer_region_id) if producer_region_id
    all
  end

  def self.type_filter(type_id)
    return where(product_type_id: type_id) if type_id
    all
  end

  def self.search(search_text)
    search_for(search_text)
  end

  def self.filter_by_ids(product_ids_a)
    return all if product_ids_a.empty? || product_ids_a.nil?
    where('products.id IN (?)', product_ids_a)
  end

  def self.filter_by_ids_nil_allowed(product_ids_a)
    where('products.id IN (?)', product_ids_a)
  end

  def self.include_orders
    includes([{ order_products: :order }])
  end

  # def self.pending_stock(group_by)
  # 	include_orders.where('orders.status_id = 1').references(:orders).group(group_by).sum('order_products.qty')
  # end

  def self.order_by_name(direction)
    order('name ' + direction)
  end

  def self.order_by_id(direction)
    order('id ' + direction)
  end

  def ex_gst_price
    if retail_ws == 'WS'
      calculated_price * 1.29
    else
      calculated_price
      end
  end

  def self.order_by_price(direction)
    if direction == 'ASC'
      Product.all.sort_by(&:ex_gst_price)
    else
      Product.all.sort_by(&:ex_gst_price).reverse
    end
  end

  def self.order_by_stock(direction)
    order('inventory ' + direction)
  end

  def self.no_vintage_id(product_id)
    find(product_id).product_no_vintage_id
  end

  def self.no_ws_id(product_id)
    find(product_id).product_no_ws_id
  end

  def self.products_with_same_no_vintage_id(no_vintage_id)
    where(product_no_vintage_id: no_vintage_id)
  end

  def self.products_with_same_no_ws_id(no_ws_id)
    where(product_no_ws_id: no_ws_id)
  end

  def self.group_by_product_no_vintage_id
    group(:product_no_vintage_id)
  end

  def self.group_by_product_no_ws_id
    group(:product_no_ws_id)
  end

  def self.group_by_product_id
    group(:id)
  end

  # transform column is no_vintage_id, no_ws_id
  def self.product_price(group_by_transform_column)
    send(group_by_transform_column).average(:calculated_price).merge\
      where(retail_ws: 'WS').send(group_by_transform_column).average('calculated_price * 1.29')
  end

  def self.product_inventory(group_by_transform_column)
    send(group_by_transform_column).sum(:inventory)
  end

  def self.stock?
    where('products.inventory > 0')
  end

  def self.sample_products(staff_id = nil, row = 10)
    return joins(:orders).where('orders.qty> 0 AND orders.total_inc_tax = 0').group('products.id').order("orders.id DESC").limit(row) if staff_id.nil?
    customer_id = Staff.find(staff_id).pick_up_id
    joins(:orders).where('orders.qty> 0 AND orders.total_inc_tax = 0 AND orders.customer_id = ?', customer_id).group('products.id').order("orders.id DESC").limit(row)
  end

  def self.autocomplete(term)
    where('LOWER(name) LIKE ?', term.downcase)
  end

  def self.filter_by_product_id(id)
    where(id: id)
  end

  def self.filter_by_product_no_ws_id(id)
    where(product_no_ws_id: id)
  end

  def self.filter_by_product_no_vintage_id(id)
    where(product_no_vintage_id: id)
  end

  def self.incompleted
    where('product_no_vintage_id IS NULL OR product_no_ws_id IS NULL OR producer_country_id IS NULL')
  end

  private

  def bigcommerce_inventory_overwrite
    # Bigcommerce::Product.update(self.id, inventory_level: self.inventory)
  end
end
