class XeroOverpayment < ActiveRecord::Base
	include CleanData
	self.primary_key = 'xero_overpayment_id'

	has_many :xero_op_allocations
	belongs_to :xero_invoice
	belongs_to :xero_contact

	def scrape
		xero = XeroConnection.new.connect

		all_overpayments = xero.Overpayment.all

		all_overpayments.each do |op|

			date = map_date(op.date)
			updated_date = map_date(op.updated_date_utc)

			time = Time.now.to_s(:db)

			contact_name = remove_apostrophe(op.contact_name)

			sql = "INSERT INTO xero_payments (xero_overpayment_id, xero_invoice_id,\
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
end
