require 'clean_data.rb'

class XeroCnAllocation < ActiveRecord::Base
	include CleanData
	self.primary_key = 'xero_cn_allocation_id'

	belongs_to :xero_invoice
	belongs_to :xero_credit_note

	def scrape(allocations, credit_note_id)

		allocations.each do |a|

			time = Time.now.to_s(:db)

			date = map_date(a.date)

			sql = "INSERT INTO xero_cn_allocations (xero_cn_allocation_id,\
			xero_credit_note_id, applied_amount, date, xero_invoice_id, invoice_number,\
			created_at, updated_at) VALUES ('#{SecureRandom.uuid}', '#{credit_note_id}',\
			'#{a.applied_amount}', '#{date}' '#{a.invoice_id}',\
			'#{a.invoice_number}', '#{time}', '#{time}')"

			ActiveRecord::Base.connection.execute(sql)
		end

	end
end
