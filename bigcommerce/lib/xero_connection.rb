require 'rubygems'
require 'xeroizer'

class XeroConnection

	def connect

		client = Xeroizer::PrivateApplication.new('YLOXMTHAIZFN3UOE5C2DTG4HHEPKD7', '9FQENZIBR4STELO2PM1PD4ZUM3UIMP', "config/privatekey.pem", :unitdp => 4)
		return client

	end
end