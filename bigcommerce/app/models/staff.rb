require 'csv'

class Staff < ActiveRecord::Base
	has_many :customers
	has_many :orders

	has_many :staff_time_periods
	has_one :default_average_period
	has_one :default_start_date

	# validates :email, unique: true

	has_secure_password

	# Create a new user
	# Staff.create(name: , email: , password: , password_confirmation: )

	def self.active_sales_staff
	  where('active = 1 and user_type LIKE "Sales%"')
	end

	def self.filter_by_id(staff_id)
	  return find(staff_id)
	end

	def self.nickname
		pluck("id, nickname")
	end

	def self.id_nickname_hash(staff_id)
		Staff.where(id: staff_id).pluck("id,nickname").to_h
	end

	def self.display_report(staff_id)
		find(staff_id).display_report
	end

	def self.can_update(staff_id)
		find(staff_id).can_update
	end


end
