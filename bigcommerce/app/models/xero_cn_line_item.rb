require 'clean_data.rb'

class XeroCNLineItem < ActiveRecord::Base
    include CleanData
    self.primary_key = 'xero_cn_line_item_id'

    belongs_to :xero_credit_note

    def download_line_items_from_api(xero, credit_note)
      return if credit_note.nil?
      if credit_note.credit_note_number.start_with?("CN")
        update_data_from_api(credit_note.line_items, credit_note.credit_note_id) unless credit_note.nil?
      end
    end

    def update_data_from_api(invoice_line_items, credit_note_id)
        invoice_line_items.each do |li|
            time = Time.now.to_s(:db)
            next unless cn_line_item_doesnt_exist(credit_note_id, li.description)
            line_amount = li.line_amount(true) || 1

            sql = "INSERT INTO xero_cn_line_items (xero_cn_line_item_id,\
    				xero_credit_note_id, item_code, description, quantity, unit_amount, line_amount,\
    				tax_amount, tax_type, account_code, created_at, updated_at) VALUES ('#{SecureRandom.uuid}',\
    				'#{credit_note_id}', '#{li.item_code}', \"#{li.description}\", '#{li.quantity}', '#{li.unit_amount}',\
    				'#{line_amount}', '#{li.tax_amount}', '#{li.tax_type}',\
    				'#{li.account_code}', '#{time}', '#{time}')"
            ActiveRecord::Base.connection.execute(sql)
        end
     end

    def cn_line_item_doesnt_exist(credit_note_id, description)
        return (XeroCNLineItem.where("xero_cn_line_items.xero_credit_note_id = '#{credit_note_id}' AND xero_cn_line_items.description LIKE \"#{description}\"").count == 0)
    end
end
