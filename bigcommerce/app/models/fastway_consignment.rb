class FastwayConsignment < ActiveRecord::Base
  belongs_to :manifest, class_name: 'FastwayManifest', foreign_key: 'ManifestID'
  has_many :items, class_name: 'FastwayConsignmentItem', foreign_key: 'ConsignmentID'

  def self.exists?(consignment_ids)
    where(ConsignmentID: consignment_ids)
  end
end
