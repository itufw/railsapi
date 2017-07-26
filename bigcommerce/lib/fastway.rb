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
end
