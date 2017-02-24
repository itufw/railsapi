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

	def insert_cn_allocation(allocations, credit_note_id, credit_note_number, status)
		time = Time.now.to_s(:db)
		if "allocations".eql? status
			allocations.each do |a|
				date = map_date(a.date)
				invoice = remove_apostrophe(a.invoice)

				sql = "INSERT INTO xero_cn_allocations (xero_cn_allocation_id, xero_credit_note_id,\
				applied_amount, date, xero_invoice_id, invoice_number, credit_note_number,\
				created_at, updated_at, status) VALUES ('#{SecureRandom.uuid}', '#{credit_note_id}',\
				'#{a.applied_amount}', '#{date}', '#{invoice.invoice_id}',\
				'#{invoice.invoice_number}', '#{credit_note_number}', '#{time}', '#{time}', 'allocation')"
				ActiveRecord::Base.connection.execute(sql)
			end
		elsif "payments".eql? status
			allocations.each do |a|
				date = map_date(a.date)
				sql = "INSERT INTO xero_cn_allocations (xero_cn_allocation_id, xero_credit_note_id,\
				applied_amount, date, reference, credit_note_number,\
				created_at, updated_at, status) VALUES ('#{a.payment_id}', '#{credit_note_id}',\
				'#{a.amount}', '#{date}', '#{a.reference}', '#{credit_note_number}', '#{time}',\
				'#{time}', 'payment')"
				ActiveRecord::Base.connection.execute(sql)
			end
		end
	end

end
