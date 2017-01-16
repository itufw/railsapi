require 'clean_data.rb'

class XeroOpAllocation < ActiveRecord::Base
	include CleanData
	self.primary_key = 'xero_op_allocation_id'

	belongs_to :xero_invoice
	belongs_to :xero_overpayment
	
	# NEVER USE THIS ONE!
	def scrape(allocations, overpayment_id)

		allocations.each do |a|

			time = Time.now.to_s(:db)

			date = map_date(a.date)

			sql = "INSERT INTO xero_op_allocations (xero_op_allocations,\
			xero_credit_note_id, applied_amount, date, xero_invoice_id, invoice_number,\
			created_at, updated_at) VALUES ('#{SecureRandom.uuid}', '#{overpayment_id}',\
			'#{a.applied_amount}', '#{date}' '#{a.invoice_id}',\
			'#{a.invoice_number}', '#{time}', '#{time}')"

			ActiveRecord::Base.connection.execute(sql)
		end
	end

	def insert_op_allocation(allocations, overpayment_id)
		time = Time.now.to_s(:db)

		allocations.each do |a|
			date = map_date(a.date)

			sql = "INSERT INTO xero_op_allocations (xero_op_allocation_id, xero_overpayment_id,\
			applied_amount, date, xero_invoice_id, invoice_number,\
			created_at, updated_at) VALUES ('#{SecureRandom.uuid}', '#{overpayment_id}',\
			'#{a.applied_amount}', '#{date}', '#{a.invoice_id}',\
			'#{a.invoice_number}', '#{time}', '#{time}')"
			ActiveRecord::Base.connection.execute(sql)
		end
	end
end
