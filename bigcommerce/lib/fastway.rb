class Fastway
  include HTTParty
  base_uri 'https://au.api.fastway.org/v2'

  def initialize
    @query = { query: {'api_key': Rails.application.secrets.fastway_key, 'UserID': '2374' } }
  end

  def track(trace_number)
    @query[:query]['CountryCode'] = 1
    begin
      if trace_number.is_a?Array
        @query[:query]['LabelNoList'] = trace_number.join(';')

        if trace_number.count >= 10
          self.class.post('/tracktrace/massdetail', @query)
        else
          self.class.get('/tracktrace/massdetail', @query)
        end
      else
        self.class.get('/tracktrace/detail/'+ trace_number, @query)
      end
    rescue
      puts 'Time out in tracing'
      retry
    end
  end

  def get_open_manifest
    self.class.get('/fastlabel/getopenmanifest', @query)
  end

  def list_consignments(manifest_id = nil, consignment_id = nil)
    return if manifest_id.nil? && consignment_id.nil?

    @query[:query]['ManifestId'] = manifest_id.to_i unless manifest_id.nil?
    @query[:query]['ConsignmentID'] = consignment_id.to_i unless consignment_id.nil?

    self.class.get('/fastlabel/listconsignments', @query)
  end

  # include consignments!
  def get_closed_manifest(number_of_days = 2)
    @query[:query]['NumDays'] = number_of_days.to_i
    self.class.get('/fastlabel/list-closed-manifests', @query)
  end

  def get_manifest(type = 'closed', multiBusinessID = nil, manifestID = nil)
    # type in [closed, open, all]
    @query[:query][:Type] = type
    @query[:query][:MultiBusinessID] = multiBusinessID unless multiBusinessID.nil?
    @query[:query][:ManifestID] = manifestID unless manifestID.nil?

    self.class.get('/fastlabel/listmanifests', @query)
  end

  def add_manifest
    # UserID - The UserID (from List Users) who is creating the manifest. Optional only if the Account only has one user.
    # Description - A short description to describe the manifest (Optional).
    # MultiBusinessID - The BusinessID (from List MultiBusiness Businesses) to create the manifest under. Optional, if omitted the manifest will be created under the parent company.
    # AutoImport - true or false, used to mark the Manifest as AutoImport (Optional). If this is true then you must mark it complete once finished, see Mark manifest complete
    self.class.get('/fastlabel/addmanifest', @query)
  end

  def add_consignment(order, dozen, half_dozen)
    # ManifestID - Optional. The ID of a manifest (from List Manifests) to add the consignment to. If omitted, defaults to the manifest that would be returned from Get Open Manifest.
    # CostCenterID - Optional. The ID (from List Cost Centers) of a cost center to log this consignment against.
    # UserID - A UserID from the List Users method.
      # Receiver Details:
    # AccountNo - Optional. Your unique reference for this customer.
    # ContactName - Optional. The contact name of someone at the receivers company.
    # CompanyName - The name of the receiving company.
    # Address1 - Receiver address line 1.
    # Address2 - Optional. Receiver address line 2.
    # Suburb - Receiver suburb.
    # Postcode - Receiver postcode.
      # Note: - The Suburb/Postcode combination must match our Price Service Calculator. See List Delivery Suburbs for a list.
    # Contact Details:
    # ContactEmail - Optional. The Email Address of the contact. ContactPhone - Optional. The Phone Number of the contact. ContactMobile - Optional. The Mobile Number of the contact.
    # Special Instructions:
    # SpecialInstruction1 - Optional. The first Special Instruction line.
    # SpecialInstruction2 - Optional. The second Special Instruction line.
    # SpecialInstruction3 - Optional. The third Special Instruction line.
    # Extras:
    # ApplyRurals - Optional. Specify 'true' or 'false'. If omitted, defaults to 'false'.
    # ApplySaturdayDelivery - Optional. Specify 'true' or 'false'. If omitted, defaults to 'false'.
    # Consignment Items:
    # Items - Mandatory to have at least one item. Items have 3 properties:
    # Reference - Optional. Your own item reference.
    # Quantity - Quantity of the same item.
    # Weight - Weight in kg. Items cannot have a weight > 25kg.
    # Items are specified using parameters named as follows: Items[0].Reference
    # Items[0].Quantity
    # Items[0].Weight
    # Items[0].Packaging - for custom parcel types (see List Custom Parcel Types) Items[1].Reference
    # Items[1].Quantity
    # Items[1].Weight
    # Items[1].Packaging

    customer = order.customer
    packaging = packaging_selection(order)
    item_number = 0

    @query[:query][:CompanyName] = customer.actual_name
    @query[:query][:Address1] = order.street
    @query[:query][:Suburb] = order.city
    @query[:query][:Postcode] = order.postcode

    @query[:query][:SpecialInstruction1] = order.SpecialInstruction1 unless order.SpecialInstruction1.nil?
    @query[:query][:SpecialInstruction2] = order.SpecialInstruction2 unless order.SpecialInstruction2.nil?
    @query[:query][:SpecialInstruction3] = order.SpecialInstruction3 unless order.SpecialInstruction3.nil?

    if dozen > 0
      @query[:query]["items[#{item_number}].Reference"] = order.id
      @query[:query]["items[#{item_number}].Quantity"] = dozen
      @query[:query]["items[#{item_number}].Weight"] = 5
      @query[:query]["items[#{item_number}].Packaging"] = packaging
      item_number += 1
    end

    pacakging = 17 if packaging == 18
    if half_dozen > 0
      @query[:query]["items[#{half_dozen}].Reference"] = order.id
      @query[:query]["items[#{half_dozen}].Quantity"] = half_dozen
      @query[:query]["items[#{half_dozen}].Weight"] = 5
      @query[:query]["items[#{half_dozen}].Packaging"] = packaging
    end

    # send request
    self.class.get('/fastlabel/addconsignment', @query)
  end

  def remove_consignment(consignment_id)
    @query[:query][:ConsignmentID] = consignment_id
    self.class.get('/fastlabel/removeconsignment', @query)
  end

  def packaging_selection(order)
    # Packaging codes are as follows: (please use the numeric code)
    # Parcel = 1
    # Satchel A2 = 4
    # Satchel A3 = 5
    # Satchel A4 (Not available in Australia) = 6 Satchel A5 (Not available in South Africa) = 7
    result = psc(order.city, order.postcode, 5)
    parcel_color = result['result']['services'].select{|x| x.values().include? 'Parcel'}.first['labelcolour_pretty_array']
    return 18 if (parcel_color.include? 'GREEN') || (parcel_color.include? 'ORANGE')
    1
  end

  def psc(suburb, postcode, weight)
    # RFCode - The RFCode of the pickup franchise (eg SYD, NPE, AUK). See the List Regional Franchises method for a more comprehensive list.
    # Suburb - The destination suburb (eg Homebush, Newcastle, Bunbury)
    # DestPostcode - The destination postcode (eg 2140, 4112, 4176)
    # WeightInKg - The total weight of the parcel, in kilograms. 25kg maximum for NZ/AU/IE, and 30kg maximum for SA
    # LengthInCm - Optional, used for specifying the length parameter of a cubic weight (in centimetres). If specified, Width and Height should also be specified.
    # WidthInCm - Optional, used for specifying the width parameter of a cubic weight (in centimetres). If specified, Length and Height should also be specified.
    # HeightInCm - Optional, used for specifying the height parameter of a cubic weight (in centimetres). If specified, Width and Length should also be specified.
    # AllowMultipleRegions - Optional, if set to 'true' then will return information about the multiple region matches instead of throwing an error
    # ShowBoxProduct - Optional, if set to 'true' it will also display box product options
    @query[:query][:RFCode] = 'MEL'
    @query[:query][:Suburb] = suburb
    @query[:query][:DestPostcode] = postcode
    @query[:query][:WeightInKg] = weight
    @query[:query][:ShowBoxProduct] = true
    self.class.get('/psc/lookup', @query)
  end
end
