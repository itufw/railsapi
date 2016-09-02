require 'xero_connection.rb'
require 'clean_data.rb'

class XeroContact < ActiveRecord::Base
	self.primary_key = 'xero_contact_id'

	has_many :xero_credit_notes
	has_many :xero_invoices
	has_many :xero_receipts
	has_many :xero_payments

	def scrape
		clean = CleanData.new
		xero = XeroConnection.new.connect

		all_contacts = xero.Contact.all

		all_contacts.each do |c|

			name = clean.remove_apostrophe(c.name) unless c.name.nil?
			firstname = clean.remove_apostrophe(c.first_name) unless c.first_name.nil?
			updated_date = clean.map_date(c.updated_date_utc.to_s)
			time = Time.now.to_s(:db)

			sql = "INSERT INTO xero_contacts (xero_contact_id, name, firstname,\
			email, skype_username, bank_account_details, status, is_customer, is_supplier,\
			date_modified, created_at, updated_at) VALUES ('#{c.contact_id}', '#{name}',\
			'#{firstname}', '#{c.email_address}','#{c.skype_user_name}',\
			'#{c.bank_account_details}', '#{c.contact_status}', '#{c.is_customer}','#{c.is_supplier}',\
			'#{updated_date}', '#{time}', '#{time}')"

			ActiveRecord::Base.connection.execute(sql)

		end

	end
end
