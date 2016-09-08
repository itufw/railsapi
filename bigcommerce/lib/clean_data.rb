class CleanData

	def remove_apostrophe(text)
		return text.gsub("'","''")
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

end