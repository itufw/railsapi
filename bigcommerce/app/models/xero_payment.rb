require 'xero_connection.rb'
require 'clean_data.rb'

class XeroPayment < ActiveRecord::Base
	include CleanData
	self.primary_key = 'xero_payment_id'

	belongs_to :xero_invoice
	belongs_to :xero_contact

	def scrape
		xero = XeroConnection.new.connect

		all_payments = xero.Payment.all

		all_payments.each do |p|

			date = map_date(p.date)
			updated_date = map_date(p.updated_date_utc)

			time = Time.now.to_s(:db)

			contact_name = clean.remove_apostrophe(p.contact_name)

			sql = "INSERT INTO xero_payments (xero_payment_id, xero_invoice_id,\
			invoice_number, invoice_type, xero_contact_id, contact_name,\
			xero_account_id, bank_amount, amount, currency_rate, date, updated_date,\
			payment_type, status, reference, is_reconciled, created_at, updated_at)\
			VALUES ('#{p.payment_id}', '#{p.invoice_id}', '#{p.invoice_number}', '#{p.invoice_type}',\
			'#{p.contact_id}', '#{contact_name}', '#{p.account_id}', '#{p.bank_amount}' \
			'#{p.amount}', '#{p.currency_rate}', '#{date}', '#{updated_date}', '#{p.payment_type}',\
			'#{p.status}', '#{p.reference}', '#{p.is_reconciled}', '#{time}', '#{time}')"

			ActiveRecord::Base.connection.execute(sql)
		end
	end
end
