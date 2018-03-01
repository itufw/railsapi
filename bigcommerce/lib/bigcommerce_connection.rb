require 'bigcommerce'

class BigcommerceConnection
	# Set them to ENV variables
	Bigcommerce.configure do |config|
		config.auth = 'legacy'
		# config.url = "https://store-35510.mybigcommerce.com/api/v2/"
		config.url = "https://www.untappedwines.com.au/api/v2/"
		config.username = "itufw"
		config.api_key = "9ad399ba11e26ff7d9806f17801d6135e48e1f94"
	end
end
