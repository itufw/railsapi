load 'fastway.rb'

module FastwayApi
  def overwrite_instruction
    orders = Order.joins(:customer).select('customers.SpecialInstruction1 AS customer_ins, orders.SpecialInstruction1 AS order_ins, orders.id AS order_id, customers.id AS customer_id').where('customers.SpecialInstruction1 IS NULL AND orders.id > 20000')
    orders = orders.select{|x| x}
    while !orders.blank?
      order = orders.delete_at(0)
      consignment = FastwayConsignment.joins(:items).where("Reference LIKE '%#{order.order_id}%'").order('CreateDate DESC').first

      next if consignment.nil?

      Customer.find(order.customer_id).update_attributes({
          'SpecialInstruction1': consignment.SpecialInstruction1,\
          'SpecialInstruction2': consignment.SpecialInstruction2,\
          'SpecialInstruction3': consignment.SpecialInstruction3
      })

      orders = orders.reject{|x| x.customer_id == order.customer_id}
    end
  end

  def wake_signatures
    fastway = Fastway.new()
    delivery_labels = FastwayTrace.select('distinct(LabelNumber)').completed.map(&:LabelNumber)
    while !delivery_labels.blank?
      selected_labels = delivery_labels[0..15]
      response = fastway.track(selected_labels)
      puts response
      return response if resposne['result'].nil?
      delivery_labels = delivery_labels.reject{|x| selected_labels.include?x}
    end
  end

  def trace_events
    fastway = Fastway.new()

    # Delete Uncompleted Signature Obtained Record
    # uncompleted_trace = FastwayTrace.where(Description: 'Signature Obtained', contactName: '').delete_all

    # delivered_label = FastwayTrace.completed.map(&:LabelNumber)
    # undelivered_label = FastwayConsignmentItem.pending_label(delivered_label).map(&:LabelNumber)

    # DO NOT Use
    # Testing Only
    # fast_orders = Order.select('track_number').where('courier_status_id = 4 AND track_number IS NOT NULL AND date_created > ?', (Date.today-3.days).to_s(:db))

    fast_orders = Order.joins(:status).select('track_number').where('courier_status_id = 4 AND track_number IS NOT NULL AND statuses.in_transit = 1')
    undelivered_label = fast_orders.map(&:track_number).join(';').split(';')
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
          fastway_trace.Signature=label['Signature'] if fastway_trace.Description=="Signature Obtained" && (fastway_trace.Signature=="" || fastway_trace.Signature.nil?) && !label['Signature'].nil?
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
