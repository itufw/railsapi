require 'xero_connection.rb'
require 'clean_data.rb'

class XeroReceipt < ActiveRecord::Base
	include CleanData
	self.primary_key = 'xero_receipt_id'

	belongs_to :xero_contact

	def scrape

		xero = XeroConnection.new.connect

		all_receipts = xero.Receipt.all

		all_receipts.each do |r|

			date = map_date(r.date.to_s)
			updated_date = map_date(r.updated_date_utc.to_s)

			time = Time.now.to_s(:db)

			sql = "INSERT INTO xero_receipts (xero_receipt_id, xero_contact_id, contact_name,\
			xero_user_id, user_firstname, user_lastname, receipt_number, sub_total, total_tax,\
			total, date, updated_date, url, reference, line_amount_types, created_at, updated_at)\
			VALUES ('#{r.receipt_id}', '#{r.contact_id}', '#{r.contact_name}', '#{r.user_id}',\
			'#{r.user_firstname}', '#{r.user_lastname}', '#{r.receipt_number}', '#{r.sub_total}',\
			'#{r.total_tax}', '#{r.total}', '#{date}', '#{updated_date}', '#{r.url}', '#{r.reference}',\
			'#{r.line_amount_types}', '#{time}', '#{time}')"

			ActiveRecord::Base.connection.execute(sql)
		end

	end
end
