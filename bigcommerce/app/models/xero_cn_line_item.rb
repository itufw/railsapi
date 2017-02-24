require 'clean_data.rb'

class XeroCNLineItem < ActiveRecord::Base

	include CleanData
	self.primary_key = 'xero_cn_line_item_id'

  belongs_to :xero_credit_note

  def download_data_from_api(invoice_line_items, credit_note_id)
		invoice_line_items.each do |li|
			time = Time.now.to_s(:db)

			if cn_line_item_doesnt_exist(li.line_item_id)
				sql = "INSERT INTO xero_cn_line_items (xero_cn_line_item_id,\
				xero_credit_note_id, item_code, description, quantity, unit_amount, line_amount,\
				tax_amount, tax_type, account_code, created_at, updated_at) VALUES ('#{SecureRandom.uuid}',\
				'#{credit_note_id}', '#{li.item_code}', '#{li.description}', '#{li.quantity}', '#{li.unit_amount}',\
				'#{li.line_amount(true)}', '#{li.tax_amount}', '#{li.tax_type}',\
				'#{li.account_code}', '#{time}', '#{time}')"
			  ActiveRecord::Base.connection.execute(sql)
		end
	end

	def cn_line_item_doesnt_exist(line_item_id)
		if XeroCNLineItem.where(xero_cn_line_item_id: line_item_id).count > 0
			return false
		else
			return true
		end
	end

end
