namespace :invoice_sync do
	desc "Rake task to update data"

	task :xero_sync => :environment do
	  start_time = Time.now
	  puts "Xero Sync #{start_time} started"
	  XeroController.new.update_xero_invoices
	  XeroController.new.link_bigc_xero_orders
	  XeroController.new.export_invoices_to_xero
	  puts "Xero Sync #{Time.now} ended"
	  XeroRevision.updated(start_time)
	end
end