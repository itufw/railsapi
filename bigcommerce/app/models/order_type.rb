class OrderType < ActiveRecord::Base
	validates :name, :description, :presence => true
	validates :name, length: { is: 3}, uniqueness: true
	validates :name, format: {with: /[a-zA-Z]{3}/, message: "accepts only alphabetical characters"}
	validates :description, format: {with: /\A[0-9a-z\s._-]+\z/i, message: "accepts only word characters, dots, dashes and underscores."}
	validates :description, length: {minimum: 5, maximum: 120}
end
