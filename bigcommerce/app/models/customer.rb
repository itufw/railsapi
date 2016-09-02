require 'bigcommerce_connection.rb'
require 'clean_data.rb'
require 'csv'

class Customer < ActiveRecord::Base
	has_many :orders
	has_many :addresses

	belongs_to :cust_type
	belongs_to :cust_group
	belongs_to :cust_style
	belongs_to :staff

	scoped_search on: [:firstname, :lastname, :company, :actual_name]

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
		clean = CleanData.new

		firstname = clean.remove_apostrophe(c.first_name)
		lastname = clean.remove_apostrophe(c.last_name)
		company = clean.remove_apostrophe(c.company)
		notes = clean.remove_apostrophe(c.notes)
		email = clean.remove_apostrophe(c.email)
		date_created = clean.map_date(c.date_created)
		date_modified = clean.map_date(c.date_modified)
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


	def csv_import

		CSV.foreach("db/csv/cust_ref.csv", headers: true) do |row|

			row_hash = row.to_hash

			if !row_hash['Actual Name'].blank?
				actual_name = row_hash['Actual Name'].force_encoding("UTF-8") 
			else
				actual_name = nil
			end

			Customer.update(row_hash['Customer ID'], actual_name: actual_name,\
				staff_id: row_hash['Owner'], cust_type_id: row_hash['CustType'],\
				cust_group_id: populate(row_hash['Group Name']),\
				cust_style_id: populate(row_hash['CustStyle']),\
				cust_store_id: populate(row_hash['CustIdentifier']),\
				region:  populate(row_hash['Region']))
		end

	end

	def populate(string)
		if string != '0'
			return string
		else
			return nil
		end
	end

	def self.staff_search_filter(search_text = nil, staff_id = nil)
		return where(staff_id: staff_id).search_for(search_text) if staff_id
		return all.search_for(search_text)
	end

	def self.customer_name(actual_name, firstname, lastname)
		name = ""	
		if actual_name.present?
		  name = actual_name
		elsif firstname.present? || lastname.present? ||
		  name = firstname + ' ' + lastname
		end
		return name
	end

	def self.get_customer(id)
		find(id)
	end


end
