require 'clean_data.rb'
class XeroOverpayment < ActiveRecord::Base
	include CleanData
	self.primary_key = 'xero_overpayment_id'

	has_many :xero_op_allocations
	belongs_to :xero_invoice
	belongs_to :xero_contact

# NEVER USE THIS ONE!
	def scrape
		xero = XeroConnection.new.connect

		all_overpayments = xero.Overpayment.all

		all_overpayments.each do |op|

			date = map_date(op.date)
			updated_date = map_date(op.updated_date_utc)

			time = Time.now.to_s(:db)

			contact_name = remove_apostrophe(op.contact_name)

			sql = "INSERT INTO xero_overpayments (xero_overpayment_id, xero_invoice_id,\
			invoice_number, xero_contact_id, contact_name, sub_total, total_tax, total,\
			remaining_credit, date, updated_date, type, status, line_amount_types,\
			currency_code, has_attachments, created_at, updated_at)\
			VALUES ('#{op.overpayment_id}', '#{op.invoice_id}', '#{op.invoice_number}',\
			'#{op.contact_id}', '#{contact_name}', '#{op.sub_total}', '#{op.total_tax}',\
			'#{op.total}', '#{op.remaining_credit}', '#{date}', '#{updated_date}', '#{op.type}',\
			'#{op.status}', '#{op.line_amount_types}', '#{op.currency_code}', '#{op.has_attachments}',\
			'#{time}', '#{time}')"

			ActiveRecord::Base.connection.execute(sql)

			XeroOpAllocation.new.scrape(op.allocations, op.overpayment_id)
		end
	end

	def download_data_from_api(modified_since_time)
		xero = XeroConnection.new.connect
		overpayment = xero.Overpayment.all(modified_since: modified_since_time)
		overpayment.each do |op|
			insert_or_update_overpayment(op)
		end
	end

	def insert_or_update_overpayment(op)
		date = map_date(op.date)
		updated_date = map_date(op.updated_date_utc)
		time = Time.now.to_s(:db)
		contact_name = remove_apostrophe(op.contact_name)
		if 'false'.eql? op.has_attachments
			has_attachments = 1
		else
			has_attachments = 0
		end

		if overpayment_doesnt_exist(op.overpayment_id)
			sql = "INSERT INTO xero_overpayments (xero_overpayment_id, \
			xero_contact_id, contact_name, sub_total, total_tax, total,\
			remaining_credit, date, updated_date, note, status, line_amount_types,\
			currency_code, has_attachments, created_at, updated_at)\
			VALUES ('#{op.overpayment_id}', \
			'#{op.contact_id}', '#{contact_name}', '#{op.sub_total}', '#{op.total_tax}',\
			'#{op.total}', '#{op.remaining_credit}', '#{date}', '#{updated_date}', '#{op.type}',\
			'#{op.status}', '#{op.line_amount_types}', '#{op.currency_code}', '#{has_attachments}',\
			'#{time}', '#{time}')"
			allocations = op.allocations
			if allocations != nil
				XeroOpAllocation.new.insert_op_allocation(allocations,op.overpayment_id)
			end


		else
			sql = "UPDATE xero_overpayments SET xero_overpayment_id = '#{op.overpayment_id}', \
			xero_contact_id = '#{op.contact_id}', contact_name = '#{contact_name}', sub_total = '#{op.sub_total}',\
			total_tax = '#{op.total_tax}', total = '#{op.total}', remaining_credit = '#{op.remaining_credit}',\
			date = '#{date}', updated_date = '#{time}', note = '#{op.type}', status = '#{op.status}',\
			line_amount_types = '#{op.line_amount_types}', currency_code = '#{op.currency_code}',\
			has_attachments =  '#{has_attachments}', updated_at = '#{time}'\
			WHERE xero_overpayment_id = '#{op.overpayment_id}'"
		end
		ActiveRecord::Base.connection.execute(sql)
	end

	def overpayment_doesnt_exist(overpayment_id)
			if XeroOverpayment.where(xero_overpayment_id: overpayment_id).count == 0
					return true
			else
					return false
			end
	end

	def self.get_remaining_credit(overpayment_id)
		where(" status in ( 'AUTHORISED', 'PAID' ) and xero_contact_id = '#{overpayment_id}'")
	end

	def self.sum_remaining_credit
		sum('remaining_credit')
	end


end
