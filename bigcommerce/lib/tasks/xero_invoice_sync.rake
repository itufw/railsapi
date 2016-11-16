namespace :xero_invoice_sync do
	task :sync => :environment do
		start_time = Time.now
		puts "Xero Sync #{start_time} started"
		XeroController.new.link_bigc_xero_orders
		puts "Xero Invoices are linked to Orders"
		XeroController.new.export_invoices_to_xero
		puts "Xero Sync #{Time.now} ended"
		XeroRevision.updated(start_time)
	end
end