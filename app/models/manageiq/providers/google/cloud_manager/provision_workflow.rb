class ManageIQ::Providers::Google::CloudManager::ProvisionWorkflow < ManageIQ::Providers::CloudManager::ProvisionWorkflow
  def allowed_instance_types(_options = {})
    source = load_ar_obj(get_source_vm)
    ems = source.try(:ext_management_system)
    architecture = source.try(:hardware).try(:bitness)
    virtualization_type = source.try(:hardware).try(:virtualization_type)
    root_device_type = source.try(:hardware).try(:root_device_type)

    return {} if ems.nil?
    available = ems.flavors
    methods = ["supports_#{architecture}_bit?".to_sym, "supports_#{virtualization_type}?".to_sym]

    methods.each { |m| available = available.select(&m) if ManageIQ::Providers::Google::CloudManager::Flavor.method_defined?(m) }

    available.each_with_object({}) { |f, hash| hash[f.id] = display_name_for_name_description(f) }
  end

  def allowed_floating_ip_addresses(_options = {})
    src = resources_for_ui
    return {} if src[:ems].nil?

    load_ar_obj(src[:ems]).floating_ips.available.each_with_object({}) do |ip, hash|
      next unless ip_available_for_selected_network?(ip, src)
      hash[ip.id] = ip.address
    end
  end

  def allowed_zones(_options = {})
    allowed_ci(:zones, [:cloud_network])
  end

  private

  def dialog_name_from_automate(message = 'get_dialog_name')
    super(message, {'platform' => 'google'})
  end

  def self.allowed_templates_vendor
    'google'
  end

  def ip_available_for_selected_network?(ip, src)
    ip.cloud_network_only? != src[:cloud_network_id].nil?
  end
end
