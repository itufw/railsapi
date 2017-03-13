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
				invoice = a.invoice
				if cn_allocation_does_not_exist(invoice, credit_note_number)
					sql = "INSERT INTO xero_cn_allocations (xero_cn_allocation_id, xero_credit_note_id,\
					applied_amount, date, xero_invoice_id, invoice_number, credit_note_number,\
					created_at, updated_at, status) VALUES ('#{SecureRandom.uuid}', '#{credit_note_id}',\
					'#{a.applied_amount}', '#{date}', '#{invoice.invoice_id}',\
					'#{invoice.invoice_number}', '#{credit_note_number}', '#{time}', '#{time}', 'allocation')"
					ActiveRecord::Base.connection.execute(sql)
				end
			end
		end
	end

	def cn_allocation_does_not_exist(invoice, credit_note_number)
		return (XeroCnAllocation.where("xero_cn_allocations.credit_note_number = '#{credit_note_number}' AND xero_cn_allocations.xero_invoice_id = '#{invoice.invoice_id}'").count == 0 )
	end

	def self.apply_to_invoices_or_cn_number(invoice_ids, credit_note_number)
		where("xero_cn_allocations.xero_invoice_id IN (?) OR xero_cn_allocations.credit_note_number IN (?)", invoice_ids, credit_note_number)
	end

	def self.apply_to_invoices(invoice_ids)
		where("xero_cn_allocations.xero_invoice_id IN (?)", invoice_ids)
	end

	def self.apply_to_orders(invoice_numbers)
		where("xero_cn_allocations.invoice_number IN (?)", invoice_numbers)
	end

	def self.group_by_orders
		group(:invoice_number)
	end

	def self.sum_applied_amount
		sum(:applied_amount)
	end

	def self.apply_from_credit_note_number(credit_note_number)
		where("xero_cn_allocations.credit_note_number IN (?)", credit_note_number)
	end
end
