require 'clean_data.rb'


class XeroInvoiceLineItem < ActiveRecord::Base
	self.primary_key = 'xero_invoice_line_item_id'

	belongs_to :xero_invoice

	def scrape(invoice_line_items, invoice_id)
		clean = CleanData.new
		invoice_line_items.each do |li|

			if XeroInvoiceLineItem.where(xero_invoice_line_item_id: li.line_item_id) == 0

				time = Time.now.to_s(:db)

				description = clean.remove_apostrophe(li.description)

				sql = "INSERT INTO xero_invoice_line_items (xero_invoice_line_item_id,\
				xero_invoice_id, item_code, description, unit_amount, line_amount, tax_amount,\
				qty, tax_type, account_code, created_at, updated_at) VALUES ('#{li.line_item_id}',\
				'#{invoice_id}', '#{li.item_code}', '#{description}', '#{li.unit_amount}',\
				'#{li.line_amount}', '#{li.tax_amount}', '#{li.quantity}', '#{li.tax_type}',\
				'#{li.account_code}', '#{time}', '#{time}')"

				ActiveRecord::Base.connection.execute(sql)
			end

		end
	end
end
