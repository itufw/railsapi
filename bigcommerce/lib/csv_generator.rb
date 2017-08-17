module CsvGenerator
  def export_to_csv(objects)
    return if objects.blank?
    attributes = objects.first.attributes.keys()
    CSV.generate(headers: true) do |csv|
      csv << attributes

      objects.each do |line|
        csv << attributes.map{ |attr| line.send(attr) }
      end
    end
  end
end
