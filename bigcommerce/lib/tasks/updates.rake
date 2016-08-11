namespace :updates do
	desc "Rake task to update data"
	task :cron => :environment do
	  AdminController.update_products
	  puts "Updated Products"
	  AdminController.update_customers
	  puts "Updated Customers"
	  AdminController.update_orders
	  puts "Updated Orders"
	end
end