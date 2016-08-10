require 'csv'

class CSVImport

	def do(model, filename, *except_columns)

		filepath = "db/csv/" + filename +  ".csv"

		CSV.foreach(filepath, encoding: "ISO8859-1", headers: true) do |row|

			row_hash = row.to_hash
			hash_except = row_hash.except(*except_columns)

			# change this
			hash_except.each do |k,v|
				hash_except[k] = return_null(v)
			end
			
			model_row = model.where(id: hash_except["id"])

	       	if !model_row.blank?

	        	model_row.first.update_attributes(hash_except)
	      	else
	         	model.create!(hash_except)
	       	end

	       	if !except_columns.nil?
	       		h = Hash.new
	       		except_columns.each do |e|
	       			h[e] = row_hash[e]
	       		end
	       		model.update(row_hash["id"], h)
	       	end

			
		end

	end

	def return_null(string)

		if string != '0' and string != 'na' and string != '#N/A' and string != '#VALUE!' and string != 'na na'
			return string
		else
			return nil
		end

	end


end