require "i18n"

module CleanData

	def remove_apostrophe(text)
		return text.gsub("'","''") unless text.nil?
	end

	def map_date(date)
		return_date = "0000-00-00 00:00:00"
		if !date.to_s.nil? && date.to_s.strip.length != 0
			return_date = date.to_s.in_time_zone('Melbourne').strftime("%Y-%m-%d %H:%M:%S")
		end
		return return_date
	end

	def convert_bool(text)
		if(text == 'false')
			return 0
		else
			return 1
		end
	end

	def convert_empty_list(list)
		unless !list.empty?
			return ''
		end
	end

	def self.remove_latin_chars(string)
		I18n.transliterate(string) unless string.nil?
	end
	# def convert_to_empty_decimal(string)
	# 	if string.strip.length == 0
	# 		return '0.00'
	# 	else
	# 		return string
	# 	end
	# end

end