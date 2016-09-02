require 'xero_connection.rb'
require 'clean_data.rb'

class XeroReceipt < ActiveRecord::Base
	self.primary_key = 'xero_receipt_id'

	belongs_to :xero_contact

	def scrape

		clean = CleanData.new
		xero = XeroConnection.new.connect

		#all_receipts = xero.XeroReceipt.all

		r = xero.Receipt.first

		#all_receipts.each do |r|

			date = clean.map_date(r.date.to_s)
			updated_date = clean.map_date(r.updated_date_utc.to_s)

			time = Time.now.to_s(:db)

			sql = "INSERT INTO xero_receipts (xero_receipt_id, receipt_number, status,\
			xero_contact_id, xero_contact_name, date, date_modified, sub_total, total,\
			total_tax, created_at, updated_at) VALUES ('#{r.receipt_id}', '#{r.receipt_number}',\
			'#{r.status}', '#{r.contact.contact_id}', '#{r.contact.name}', '#{date}', '#{updated_date}',\
			'#{r.sub_total}', '#{r.total}', '#{r.total_tax}', '#{time}', '#{time}')"

			ActiveRecord::Base.connection.execute(sql)
		#end

	end
end
