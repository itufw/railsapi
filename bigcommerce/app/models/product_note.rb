class ProductNote < ActiveRecord::Base
  belongs_to :task
  belongs_to :creator, class_name: 'Staff', foreign_key: :created_by
  belongs_to :product
end
