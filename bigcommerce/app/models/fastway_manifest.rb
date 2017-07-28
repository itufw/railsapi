class FastwayManifest < ActiveRecord::Base
  has_many :consignments, class_name: 'FastwayConsignment', foreign_key: 'ManifestID'

  def self.exists?(manifest_ids)
    where(ManifestID: manifest_ids)
  end
end
