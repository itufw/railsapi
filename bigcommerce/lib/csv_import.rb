require 'csv'

class CSVImport
    def do(model, filename, *except_columns)
        filepath = 'db/csv/' + filename + '.csv'

        CSV.foreach(filepath, encoding: 'ISO8859-1', headers: true) do |row|
            row_hash = row.to_hash

            # remove except columns from the hash
            hash_except = row_hash.except(*except_columns)

            # for all the columns in the hash_except
            # change weird null type values in excel like 0, N/A, etc to NULL in the database
            hash_except.each do |k, v|
                hash_except[k] = return_null(v)
            end

            # See if the row already exists in the database
            model_row = model.where(id: hash_except['id'])

            if !model_row.blank?
                # if it exists, update it
                model_row.first.update_attributes(hash_except)
            else
                # otherwise create it
                model.create!(hash_except)
            end

            unless except_columns.nil?
                h = {}
                except_columns.each do |e|
                    h[e] = row_hash[e]
                end
                model.update(row_hash['id'], h)
            end
        end
    end

    def return_null(string)
        if (string != '0') && (string != 'na') && (string != '#N/A') && (string != '#VALUE!') && (string != 'na na')
            string
        end
    end
end
