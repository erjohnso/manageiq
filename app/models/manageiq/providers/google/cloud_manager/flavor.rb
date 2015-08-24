class ManageIQ::Providers::Google::CloudManager::Flavor < ::Flavor
  virtual_column :supports_pd,            :type => :boolean

  def supports_pd?
    block_storage_based_only?
  end
end
