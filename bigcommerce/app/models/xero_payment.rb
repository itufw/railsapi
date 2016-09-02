require 'xero_connection.rb'
require 'clean_data.rb'

class XeroPayment < ActiveRecord::Base
	belongs_to :xero_invoice
	belongs_to :xero_contact

	def scrape
		xero = XeroConnection.new.connect
		clean = CleanData.new

		all_payments = xero.Payment.all

		all_payments.each do |p|

			date = clean.map_date(p.date.to_s)
			updated_date = clean.map_date(p.updated_date_utc.to_s)

			time = Time.now.to_s(:db)

			sql = "INSERT INTO xero_payments (xero_payment_id, xero_invoice_id,\
			xero_invoice_number, invoice_type, xero_contact_id, xero_account_id,\
			xero_contact_name, payment_type, status, amount, date,\
			date_modified, created_at, updated_at) VALUES ('#{p.payment_id}',\
			'#{p.invoice_id}', '#{p.invoice.invoice_number}', '#{p.invoice.type}',\
			'#{p.invoice.contact_id}', '#{p.account_id}', '#{p.invoice.name}',\
			'#{p.payment_type}', '#{p.status}', '#{p.amount}', '#{date}', '#{updated_date}',\
			'#{time}', '#{time}')"
		end
	end
end
