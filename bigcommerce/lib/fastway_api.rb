load 'fastway.rb'

module FastwayApi
  def trace_events
    fastway = Fastway.new()
    delivered_label = FastwayTrace.completed.map(&:LabelNumber)
    undelivered_label = FastwayConsignmentItem.pending_label(delivered_label).map(&:LabelNumber)

    while !undelivered_label.blank?
      # maximum for 15, otherwise url error
      selected_labels = undelivered_label[0..15]

      response = fastway.track(selected_labels)
      return response if response['result'].nil?

      response['result'].each do |label|
        label_number = {'LabelNumber' => label['LabelNumber'], 'Reference' => label['Reference']}
        next if label['Scans'].nil?
        label['Scans'].each do |scan|
          next if FastwayTrace.exists?(label['LabelNumber'], scan['Description'], scan['StatusDescription']).count > 0
          attributes = scan.select{ |key, value| key!='CompanyInfo'}.merge(scan['CompanyInfo']).merge(label_number)
          fastway_trace = FastwayTrace.new(attributes)
          fastway_trace.save
        end
      end
      # filter out the selected labels
      undelivered_label = undelivered_label.reject {|x| selected_labels.include?x}
    end
  end

  def update_closed_manifest(number_of_days = 2)
    fastway = Fastway.new()
    response = fastway.get_closed_manifest(number_of_days)
    return if response['result'].nil?
    response['result'].each do |manifest|
      next if FastwayManifest.exists?(manifest['ManifestID']).count > 0
      fw_manifest = FastwayManifest.new(manifest.select{|key, value| key!='Consignments'})
      fw_manifest.save

      manifest['Consignments'].each do |consignment|
        next if FastwayConsignment.exists?(consignment['ConsignmentID']).count > 0
        fw_consignment = FastwayConsignment.new(consignment.select{|key, value| key != 'Items'})
        fw_consignment.ManifestID = fw_manifest.ManifestID
        fw_consignment.save

        consignment['Items'].each do |item|
          next if FastwayConsignmentItem.exists?(item['ItemID']).count > 0
          fw_item = FastwayConsignmentItem.new(item)
          fw_item.ConsignmentID = fw_consignment.ConsignmentID
          fw_item.save
        end
      end
    end
  end

end
