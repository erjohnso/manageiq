module ManageIQ::Providers::Google::CloudManager::Provision::Cloning
  def do_clone_task_check(clone_task_ref)
    source.with_provider_connection do |gce|
      instance = gce.instances[clone_task_ref]
      status   = instance.status
      return true if status == :running
      return false, status
    end
  end

  def prepare_for_clone_task
    clone_options = super

    # How many instances to request.
    # By default one instance is requested.
    # You can specify this either as an integer or as a Range,
    # to indicate the minimum and maximum number of instances to run.
    clone_options[:count] = 1

    # Specifies whether you can terminate the instance using the GCE API.
    #   true  => cannot terminate the instance using the API (i.e., the instance is “locked”)
    #   false => can    terminate the instance using the API
    # If you set this to true, and you later want to terminate the instance, you must first enable API termination.
    clone_options[:disable_api_termination] = false

    clone_options[:image_id]           = source.ems_ref
    clone_options[:instance_type]      = instance_type.name

    # Cloud Monitoring
    #   true  => Advanced Monitoring
    #   false => Basic    Monitoring
    clone_options[:monitoring_enabled] = get_option(:monitoring).to_s.downcase == "advanced"

    clone_options
  end

  def log_clone_options(clone_options)
    _log.info("Provisioning [#{source.name}] to [#{dest_name}]")
    _log.info("Source Template:                 [#{self[:options][:src_vm_id].last}]")
    if dest_zone
      _log.info("Destination Zone:   [#{dest_zone.name} (#{dest_zone.ems_ref})]")
    else
      _log.info("Destination Zone:  Default selection from provider")
    end
    _log.info("Guest Access Key Pair:           [#{clone_options[:key_name].inspect}]")
    _log.info("Instance Type:                   [#{clone_options[:instance_type].inspect}]")
    _log.info("Cloud Watch:                     [#{clone_options[:monitoring_enabled].inspect}]")

    dumpObj(clone_options, "#{log_header} Clone Options: ", $log, :info)
    dumpObj(options, "#{log_header} Prov Options:  ", $log, :info, :protected => {:path => workflow_class.encrypted_options_field_regs})
  end

  def start_clone(clone_options)
    source.with_provider_connection do |gce|
      instance = gce.instances.create(clone_options)
      return instance.id
    end
  end
end
