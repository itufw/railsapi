require 'bigcommerce_connection.rb'
require 'clean_data.rb'

class Customer < ActiveRecord::Base

	include CleanData
	has_many :orders
	has_many :addresses
	has_many :contacts
	has_many :cust_contacts
	has_many :customer_credit_apps
	belongs_to :cust_type
	belongs_to :cust_group
	belongs_to :cust_style
	belongs_to :staff
	belongs_to :xero_contact

	has_many :xero_invoices, through: :xero_contact

	geocoded_by :address
  after_validation :geocode, if: ->(obj){ obj.address.present? and obj.address_changed?}

  reverse_geocoded_by :lat, :lng
  after_validation :reverse_geocode, if: ->(obj){ obj.address.present? and obj.address_changed?}

	scoped_search on: [:firstname, :lastname, :company, :actual_name, :address]

	self.per_page = 15

	def create_in_bigcommerce
		# property :id
		# property :_authentication
		# property :count
		# property :company
		# property :first_name
		# property :last_name
		# property :email
		# property :phone
		# property :date_created
		# property :date_modified
		# property :store_credit
		# property :registration_ip_address
		# property :customer_group_id
		# property :notes
		# property :addresses
		# property :tax_exempt_category
		# property :accepts_marketing
		customer_api = Bigcommerce::Customer
		splited_name = self.actual_name.split()
		bigc_customer = customer_api.create(
			first_name: splited_name[0],
			last_name: (splited_name[1..splited_name.length].join(' ')=="") ? "UFW" : splited_name[1..splited_name.length].join(' '),
			email: (self.email.to_s=="") ? (self.actual_name.split().join('_')+"@untappedwines.com") : self.email,
			store_credit: self.store_credit || 0,
			customer_group_id: self.cust_type_id || 2,
			notes: self.notes || ""
		)
		self.id = bigc_customer.id
		self.save

		unless self.street.nil?
			customer_address = Bigcommerce::CustomerAddress.create(
			  bigc_customer.id,
			  first_name: self.firstname,
			  last_name: self.lastname,
			  phone: self.phone,
			  street_1: self.street,
			  city: self.city,
			  state: self.state,
			  zip: self.postcode,
			  country: self.country
			)
		end

		bigc_customer
	end

	# mass insert from bigcommerce api
	def scrape

		customer_api = Bigcommerce::Customer
		customer_count = customer_api.count.count

		#Bigcommerce api gives 50 items at once
		limit = 50
		customer_pages = (customer_count/limit) + 1

		page_number = 1

		# Loop through pages - each with 50 items
		customer_pages.times do

			customers = customer_api.all(page: page_number)

			customers.each do |c|

				insert_sql(c, 1)

			end

			page_number += 1
		end

	end

	# Form and execute insert/update sql statements
	def insert_sql(c, insert)

		time = Time.now.to_s(:db)

		firstname = remove_apostrophe(c.first_name)
		lastname = remove_apostrophe(c.last_name)
		company = remove_apostrophe(c.company)
		notes = remove_apostrophe(c.notes)
		email = remove_apostrophe(c.email)
		date_created = map_date(c.date_created)
		date_modified = map_date(c.date_modified)
		phone = c.phone.gsub(/\s+/, "")

		sql = cust = ""

		if insert == 1

			unallocated_staff_id = 34

			cust =  "('#{c.id}', '#{firstname}', '#{lastname}', '#{company}',\
			'#{email}', '#{phone}', '#{c.store_credit}', '#{c.registration_ip_address}',\
			'#{notes}', '#{date_created}', '#{date_modified}', '#{time}', '#{time}', '#{c.customer_group_id}', '#{unallocated_staff_id}')"

			sql = "INSERT INTO customers(id, firstname, lastname, company, email, phone,\
			store_credit, registration_ip_address, notes, date_created, date_modified,\
			created_at, updated_at, cust_type_id, staff_id) VALUES #{cust}"

		else

			sql = "UPDATE customers SET firstname = '#{firstname}', lastname = '#{lastname}', company = '#{company}',\
			email = '#{email}', phone = '#{phone}', store_credit = '#{c.store_credit}',\
			registration_ip_address = '#{c.registration_ip_address}', notes = '#{notes}', date_created = '#{date_created}',\
			date_modified = '#{date_modified}', updated_at = '#{time}', cust_type_id = '#{c.customer_group_id}' WHERE id = '#{c.id}'"


		end

    ActiveRecord::Base.connection.execute(sql)

	end

	def update_from_api(update_time)

		customer_api = Bigcommerce::Customer
		customer_count = customer_api.count(min_date_modified: update_time).count
		limit = 50
		customer_pages = (customer_count/limit) + 1

		page_number = 1

		# Loop through pages
		customer_pages.times do

			customers = customer_api.all(min_date_modified: update_time, page: page_number)

			if customers.blank?
				return
			end

			customers.each do |c|

				# If customer exists - update
				if !Customer.where(id: c.id).blank?

					insert_sql(c, 0)

				# Else - insert new customer
				else
					insert_sql(c, 1)
				end

			end
			page_number += 1

		end

	end

	def account_approval(order_total)
		return 'Approved' if order_total == 0
		return 'Hold-Account' if self.xero_contact_id.nil? || self.account_type=="COD"
		return (XeroInvoice.where("xero_contact_id = '#{self.xero_contact_id}' AND due_date < '#{Date.today.beginning_of_month.to_s(:db)}'").sum('amount_due') > 0) ? 'Hold-Overdue' : 'Approved' if self.account_type == "EOM"
		sum = XeroInvoice.where("xero_contact_id = '#{self.xero_contact_id}' AND due_date < '#{(Date.today - self.tolerance_day.to_i.days).to_s(:db)}'").sum('amount_due')
		return 'Hold-Overdue' if sum > 0
		'Approved'
	end

	def self.staff_search_filter(search_text = nil, staff_id = nil)
		return where(staff_id: staff_id).search_for(search_text) if staff_id
		return search_for(search_text) if search_text
		return all
	end

	def self.staff_filter(staff_ids)
		where(staff_id: staff_ids)
	end

	def self.cust_style_filter(cust_style_id)
		return where(cust_style_id: cust_style_id) unless cust_style_id.nil?
		return all
	end

	def self.customer_name(actual_name, firstname, lastname)
		name = ""
		if actual_name.present?
		  name = actual_name
		elsif firstname.present? || lastname.present?
		  name = firstname + ' ' + lastname
		end
		return name
	end

	def self.filter_by_id(id)
		find(id.to_i)
	end

	def self.filter_by_contact_id(id)
		where("xero_contact_id = '#{id}'").first
	end

	def self.filter_new_customer(start_date, end_date)
		where("created_at >= '#{start_date}' and created_at<='#{end_date}'")
	end

	def self.filter_by_ids(ids_array)
		return Customer.all if ids_array.nil?
		return nil if ids_array.blank?
		return where('customers.id IN (?)', ids_array)
	end

	def self.order_by_name(direction)
		order('actual_name ' + direction)
	end

	def self.order_by_staff(direction)
		includes(:staff).order('staffs.nickname ' + direction)
	end

	def self.order_by_type(direction)
		includes(:cust_type).order('cust_types.name ' + direction)
	end

	def self.order_by_style(direction)
		includes(:cust_style).order('cust_styles.name ' + direction)
	end

	def self.order_by_outstanding(direction)
		includes(:xero_contact).order('xero_contacts.accounts_receivable_outstanding ' + direction)
	end

	def self.order_by_overdue(direction)
		includes(:xero_contact).order('xero_contacts.accounts_receivable_overdue ' + direction)
	end

	def self.active_customers
		where(staff_id: Staff.active_sales_staff)
	end

	def self.insert_xero_contact_id(customer_id, xero_contact_id)
		customer = filter_by_id(customer_id)
		customer.xero_contact_id = xero_contact_id
		customer.save
	end

	def self.xero_contact_id_is_null
		where(xero_contact_id: nil)
	end

	def self.is_new_customer_for_xero(customer)
		if customer.nil?
			return false
		elsif customer.xero_contact_id.nil?
			return true
		else
			return false
		end
	end

	def self.get_xero_contact_id(customer)
		if customer.nil?
			return nil
		else
			return customer.xero_contact_id
		end
	end

	def self.is_wholesale(customer)
		return customer.cust_type_id == 2
	end

	def self.xero_contact_id_of_duplicate_customer(customer_name)
		customer = where('actual_name = ? and xero_contact_id IS NOT NULL', customer_name).first
		return customer.xero_contact_id unless customer.nil?
	end

	def self.retail_customer
		where(cust_type_id: 1)
	end

	# def self.due_date_num_days(customer)
	# 	if customer.end_of_month.nil?
	# 		return customer.num_days
	# 	else

	# 	end
	# end

	def self.staff_change(staff_id, customer_id)
		customer = filter_by_id(customer_id)
		customer.staff_id = staff_id.to_i
		customer.save
	end

	def self.include_staff
		includes(:staff)
	end

	def self.include_cust_style
		includes(:cust_style)
	end

	def self.include_all
		includes(:cust_style, :cust_type, :cust_group, :staff, :xero_contact)
	end

	def cust_style_name
		cust_style.name unless cust_style.nil?
	end

	def self.incomplete
		where('actual_name IS NULL or cust_style_id is NULL or staff_id = 34')
	end

	def self.xero_contact_is_not_null
		where('customers.xero_contact_id IS NOT NULL')
	end

	def self.outstanding_is_greater_zero
		where('xero_contacts.accounts_receivable_outstanding > 0').references(:xero_contacts)
	end

	def self.create_date_filter(start_date, end_date)
		where("date_created > '#{start_date}' and date_created <= '#{end_date}'")
	end

	def self.filter_by_staff(staff_id)
		return where(:staff_id => staff_id) unless (staff_id.nil? && staff_id.blank?)
		all
	end

	def self.count_id
		count("id")
	end

	########## GROUP BY FUNCTIONS ############

	def self.group_by_date_created
		group('DATE(customers.date_created)')
	end

	def self.group_by_week_created
			group('WEEK(customers.date_created)')
	end

	def self.group_by_month_created
		group(['MONTH(customers.date_created)', 'YEAR(customers.date_created)'])
	end

	def self.group_by_quarter_created
			group(['QUARTER(customers.date_created)', 'YEAR(customers.date_created)'])
	end

	def self.group_by_year_created
			group('YEAR(customers.date_created)')
	end

	def self.group_by_date_created_and_staff_id
		group(['customers.staff_id', 'DATE(customers.date_created)'])
	end

	def self.group_by_week_created_and_staff_id
	  group(['customers.staff_id', 'WEEK(orders.date_created)'])
	end

	def self.group_by_month_created_and_staff_id
		group(['customers.staff_id', 'MONTH(customers.date_created)', 'YEAR(customers.date_created)'])
	end

	def self.group_by_quarter_created_and_staff_id
	   group(['customers.staff_id', 'QUARTER(customers.date_created)', 'YEAR(customers.date_created)'])
	end

	def self.group_by_year_created_and_staff_id
	   group(['customers.staff_id', 'YEAR(customers.date_created)'])
	end

	def allocated_orders
		Order.where(customer_id: self.id, status_id: 1)
	end

	def allocate_products(product_id, product_qty, revision_date, user_id)
		order = allocated_orders.first
		product = Product.find(product_id)

		if order.nil?
			order = Order.new(customer_id: self.id, status_id: 1, staff_id: self.staff_id,\
		 		total_inc_tax: 0, qty: 0, items_shipped: 0, subtotal: 0,\
				discount_rate: 100, discount_amount: 0, handling_cost: 0, shipping_cost: 0,\
				wrapping_cost: 0, wet: 0, gst: 0, staff_notes: 'Allocated Order', customer_notes: '',\
				active: 1, source: 'manual', date_created: Time.now.to_s(:db),\
				created_by: user_id, last_updated_by: user_id,\
				courier_status_id: 1, account_status: 'Approved', street: self.street,\
				street_2: self.street_2, city: self.city, postcode: self.postcode, country: self.country)
	 	end
		order.qty += product_qty
		order.discount_amount += (product_qty*product.calculated_price*1.29).round(4)
		order.save

		product = OrderProduct.new(product_id: product_id, order_id: order.id, price_luc: 0,\
		 qty: product_qty, discount: 0, price_discounted: 0, qty_shipped: 0,\
		 order_discount: 100, price_handling: 0, stock_previous: 0, stock_current: product_qty,\
		 stock_incremental: product_qty, price_gst: 0, price_wet: 0, base_price: product.calculated_price*1.29,\
		 price_inc_tax: 0, display: 1, damaged: 0, revision_date: revision_date.to_s(:db),\
		 created_by: user_id, updated_by: user_id).save

		order
	end
end
