require 'clean_data.rb'


class XeroInvoiceLineItem < ActiveRecord::Base

	include CleanData
	self.primary_key = 'xero_invoice_line_item_id'

	belongs_to :xero_invoice

	def download_data_from_api(scrape, invoice_line_items, invoice_id, invoice_number)
		invoice_line_items.each do |li|

		time = Time.now.to_s(:db)

		description = remove_apostrophe(li.description)

			if scrape
				sql = "INSERT INTO xero_invoice_line_items (xero_invoice_line_item_id,\
				xero_invoice_id, invoice_number, item_code, description, quantity, unit_amount, line_amount, discount_rate,\
				tax_amount, tax_type, account_code, created_at, updated_at) VALUES ('#{li.line_item_id}',\
				'#{invoice_id}', '#{invoice_number}', '#{li.item_code}', '#{description}', '#{li.quantity}', '#{li.unit_amount}',\
				'#{li.line_amount(true)}', '#{li.discount_rate}', '#{li.tax_amount}', '#{li.tax_type}',\
				'#{li.account_code}', '#{time}', '#{time}')"
			else
				sql = "UPDATE xero_invoice_line_items SET xero_invoice_id = '#{invoice_id}',\
				invoice_number = '#{invoice_number}', item_code = '#{li.item_code}', description = '#{description}',\
				quantity = '#{li.quantity}', unit_amount = '#{li.unit_amount}', line_amount = '#{li.line_amount(true)}',\
				discount_rate = '#{li.discount_rate}', tax_amount = '#{li.tax_amount}',\
				tax_type = '#{li.tax_type}', account_code = '#{li.account_code}',\
				updated_at = '#{time}' WHERE xero_invoice_line_item_id = '#{i.line_item_id}'"
			end
			ActiveRecord::Base.connection.execute(sql)

		end
	end

end
