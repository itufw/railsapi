require 'rubygems'
require 'xeroizer'

class XeroConnection

	def connect

		client = Xeroizer::PrivateApplication.new('PJH08HPMIWBH4YBX2SDYVE7WDWX7BX', 'PPSNCIHM5WSAUDTHDVH4P6ALDYZHCT', "config/privatekey.pem", :unitdp => 4)
		return client

	end
end
