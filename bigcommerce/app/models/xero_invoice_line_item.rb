require 'clean_data.rb'


class XeroInvoiceLineItem < ActiveRecord::Base

	include CleanData
	self.primary_key = 'xero_invoice_line_item_id'

	belongs_to :xero_invoice

	def download_data_from_api(invoice_line_items, invoice_id, invoice_number)
		invoice_line_items.each do |li|

			time = Time.now.to_s(:db)

			description = remove_apostrophe(li.description)

			if invoice_line_item_doesnt_exist(li.line_item_id)
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
				updated_at = '#{time}' WHERE xero_invoice_line_item_id = '#{li.line_item_id}'"
			end
			ActiveRecord::Base.connection.execute(sql)

		end
	end

	def invoice_line_item_doesnt_exist(line_item_id)
		if XeroInvoiceLineItem.where(xero_invoice_line_item_id: line_item_id).count > 0
			return false
		else
			return true
		end
	end

	def self.is_product
		where("xero_invoice_line_items.item_code REGEXP '^[0-9]+$'")
	end

	def self.belongs_to_invoice(invoice_ids)
		where("xero_invoice_line_items.xero_invoice_id IN (?)", invoice_ids)
	end

	def self.sum_order_product_qty
		sum("xero_invoice_line_items.quantity")
	end

	def self.group_by_invoice
		group("xero_invoice_line_items.xero_invoice_id")
	end

end
