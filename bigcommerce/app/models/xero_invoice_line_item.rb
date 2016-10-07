require 'clean_data.rb'


class XeroInvoiceLineItem < ActiveRecord::Base

	include CleanData
	self.primary_key = 'xero_invoice_line_item_id'

	belongs_to :xero_invoice

	def scrape(invoice_line_items, invoice_id)
		clean = CleanData.new
		invoice_line_items.each do |li|

			time = Time.now.to_s(:db)

			description = remove_apostrophe(li.description)

			sql = "INSERT INTO xero_invoice_line_items (xero_invoice_line_item_id,\
			xero_invoice_id, item_code, description, quantity, unit_amount, line_amount, discount_rate,\
			tax_amount, tax_type, account_code, created_at, updated_at) VALUES ('#{li.line_item_id}',\
			'#{invoice_id}', '#{li.item_code}', '#{description}', '#{li.quantity}', '#{li.unit_amount}',\
			'#{li.line_amount(true)}', '#{li.discount_rate}', '#{li.tax_amount}', '#{li.tax_type}',\
			'#{li.account_code}', '#{time}', '#{time}')"

			ActiveRecord::Base.connection.execute(sql)
		end
	end
end
