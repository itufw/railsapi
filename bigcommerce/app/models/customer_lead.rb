require 'clean_data.rb'
# store the customer leads
# leads may turn to customers -> transfer data to customers table
class CustomerLead < ActiveRecord::Base
  include CleanData
  has_many :contacts
  belongs_to :cust_type
  belongs_to :cust_group
  belongs_to :cust_style
  belongs_to :staff

  geocoded_by :address
  after_validation :geocode

  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode

  self.per_page = 15

  def self.update_coordinates
    coordinate = Geocoder.coordinates(:address)
    self.latitude = coordinate.first
    self.longitude = coordinate.last
    save
  end

  def self.address
    address
  end

  def self.search(name = nil)
    return all if name.nil?
    where("customer_leads.actual_name LIKE \"%#{name}%\"")
  end

  def self.filter_staff(staff_id = nil)
    return all if staff_id.nil?
    where('customer_leads.staff_id = ?', staff_id)
  end

  def self.filter_cust_style(cust_style = nil)
    return all if cust_style.nil?
    where('customer_leads.cust_style_id = ?', cust_style)
  end

  def self.filter_by_id(lead_id)
    find(lead_id)
  end
end
