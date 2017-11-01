require 'clean_data.rb'
require 'lead_helper.rb'
# store the customer leads
# leads may turn to customers -> transfer data to customers table
class CustomerLead < ActiveRecord::Base
  include CleanData
  include LeadHelper

  has_many :contacts
  has_many :task_relations
  has_many :tasks, through: :task_relations
  belongs_to :cust_type
  belongs_to :cust_group
  belongs_to :cust_style
  belongs_to :staff

  geocoded_by :address
  after_validation :geocode, if: ->(obj){ obj.address.present? and obj.address_changed?}

  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode

  scoped_search on: %i[firstname lastname company actual_name address]

  self.per_page = 15

  def self.update_coordinates
    CustomerTag.new.insert_lead(self)

    coordinate = Geocoder.coordinates(:address)
    self.latitude = coordinate.first
    self.longitude = coordinate.last
    save
  end

  def self.address
    address
  end

  def self.staff_change(staff_id, lead_id)
    lead = filter_by_id(lead_id)
    lead.staff_id = staff_id.to_i
    lead.save
  end

  def self.filter_staff(staff_id = nil)
    return all if staff_id.nil?
    where('customer_leads.staff_id = ?', staff_id)
  end

  def self.filter_by_staff(staff_id)
    return where(staff_id: staff_id) unless (staff_id.nil? && staff_id.blank?)
    all
  end

  def self.filter_cust_style(cust_style = nil)
    return all if cust_style.nil?
    where('customer_leads.cust_style_id = ?', cust_style)
  end

  def self.filter_by_id(lead_id)
    find(lead_id)
  end

  def self.filter_by_ids(lead_ids)
    where('id IN (?)', lead_ids)
  end

  def self.filter_by_name(actual_name)
    where('actual_name LIKE ?', actual_name)
  end

  def self.active_lead
    where(id: TaskRelation.select(:customer_lead_id).map(&:customer_lead_id))
  end

  def self.order_by_name(direction)
    order('actual_name ' + direction)
  end

  def self.order_by_style(direction)
    includes(:cust_style).order('cust_style.name ' + direction)
  end

  def self.order_by_staff(direction)
    includes(:staff).order('staffs.nickname ' + direction)
  end

  def self.not_customer
    where(customer_id: [nil, 0])
  end

  def turn_customer(customer_id, date = Time.now())
    self.customer_id = customer_id
    self.turn_customer_date = date
    self.save
  end

  def convert_to_customer
    return unless self.customer_id.nil?

    # Big Commerce Customer must has a first and last name
    splited_name = self.actual_name.split()
    lastname_suffix = (splited_name[1..splited_name.length].join(' ')=="") ? "UFW" : splited_name[1..splited_name.length].join(' ')
    first_name = self.firstname.to_s=="" ? self.firstname : splited_name[0]
    last_name = self.lastname.to_s=="" ? self.lastname : lastname_suffix

    customer = Customer.new({firstname: first_name, lastname: last_name,\
      company: self.company, email: self.email, phone: self.phone, actual_name: self.actual_name,\
      staff_id: self.staff_id, cust_type_id: self.cust_type_id || 2, cust_group_id: self.cust_group_id || 0,\
      cust_style_id: self.cust_style_id.to_i.zero? ? 2 : self.cust_style_id, address: self.address,\
      lat: self.latitude, lng: self.longitude, tolerance_day: 30,\
      street: self.street, city: self.city, state: self.state,\
      postcode: self.postalcode, country: self.country})
    bc_customer = customer.create_in_bigcommerce
    lead_link_customer(self, bc_customer.id)

    customer
  end

end
