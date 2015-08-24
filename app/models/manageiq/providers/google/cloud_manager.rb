class ManageIQ::Providers::Google::CloudManager < ManageIQ::Providers::CloudManager
  require_dependency 'manageiq/providers/google/cloud_manager/auth_key_pair'
  require_dependency 'manageiq/providers/google/cloud_manager/availability_zone'
  require_dependency 'manageiq/providers/google/cloud_manager/cloud_volume'
  require_dependency 'manageiq/providers/google/cloud_manager/cloud_volume_snapshot'
  require_dependency 'manageiq/providers/google/cloud_manager/event_catcher'
  require_dependency 'manageiq/providers/google/cloud_manager/event_parser'
  require_dependency 'manageiq/providers/google/cloud_manager/flavor'
  require_dependency 'manageiq/providers/google/cloud_manager/floating_ip'
  require_dependency 'manageiq/providers/google/cloud_manager/metrics_collector_worker'
  require_dependency 'manageiq/providers/google/cloud_manager/orchestration_service_option_converter'
  require_dependency 'manageiq/providers/google/cloud_manager/orchestration_stack'
  require_dependency 'manageiq/providers/google/cloud_manager/provision'
  require_dependency 'manageiq/providers/google/cloud_manager/provision_workflow'
  require_dependency 'manageiq/providers/google/cloud_manager/refresh_parser'
  require_dependency 'manageiq/providers/google/cloud_manager/refresh_worker'
  require_dependency 'manageiq/providers/google/cloud_manager/refresher'
  require_dependency 'manageiq/providers/google/cloud_manager/template'
  require_dependency 'manageiq/providers/google/cloud_manager/vm'

  def self.ems_type
    @ems_type ||= "gce".freeze
  end

  def self.description
    @description ||= "Google Compute Engine".freeze
  end

  def self.hostname_required?
    false
  end

  validates :provider_region, :inclusion => {:in => ManageIQ::Providers::Google::Regions.names}

  def description
    ManageIQ::Providers::Google::Regions.find_by_name(provider_region)[:description]
  end

  #
  # Connections
  #

  def self.raw_connect(access_key_id, secret_access_key, service, proxy_uri = nil)
    service   ||= "GCE"
    proxy_uri ||= VMDB::Util.http_proxy_uri

    require 'google/api_client'
    # TODO(erjohnso): remove hard-coded auth attributes, and convert to symbols
    google_key_location = '/home/erjohnso/pkey.pem'
    google_client_email = '982735739546-c1gpjgnpih237338tn1top6768fp7st2@developer.gserviceaccount.com'
    scopes = ['https://www.googleapis.com/auth/compute',
              'https://www.googleapis.com/auth/devstorage.read_only',
              'https://www.googleapis.com/auth/logging.write',
              'https://www.googleapis.com/auth/cloud-platform']
    api_client_options = {
        :application_name => "manageiq",
        :application_version => "0.0.1"
    }

    key = Google::APIClient::KeyUtils.load_from_pkcs12(google_key_location, 'notasecret')
    @client = ::Google::APIClient.new(api_client_options)

    client.authorization = Signet::OAuth2::Client.new(
        {
            :audience => 'https://accounts.google.com/o/oauth2/token',
            :auth_provider_x509_cert_url => 'https://www.googleapis.com/oauth2/v1/certs',
            :auth_provider_cert_url => "https://www.googleapis.com/robot/v1/metadata/x509/#{google_client_email}",
            :issuer => google_client_email,
            :scope => 'https://www.googleapis.com/auth/prediction',
            :signing_key => key,
            :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        }
    )
    client.authorization.fetch_access_token!
  end

  def browser_url
    "https://console.developers.google.com/project/#{google_project}"
  end

  def connect(options = {})
    # TODO(erjohnso): add valid checks
    #raise "no credentials defined" if self.missing_credentials?(options[:auth_type])

    #username = options[:user] || self.authentication_userid(options[:auth_type])
    #password = options[:pass] || self.authentication_password(options[:auth_type])

    #self.class.raw_connect(username, password, options[:service], provider_region, options[:proxy_uri])
    self.class.raw_connect()
    client.discovered_api(options[:service_endpoint], options[:service_version])
  end

  def translate_exception(err)
    # TODO(erjohnso): sane error conversion messages
#    case err
#    when GCP::GCE::Errors::SignatureDoesNotMatch
#      MiqException::MiqHostError.new "SignatureMismatch - check your GCP Secret Access Key and signing method"
#    when GCP::GCE::Errors::AuthFailure
#      MiqException::MiqHostError.new "Login failed due to a bad username or password."
#    when GCP::Errors::MissingCredentialsError
#      MiqException::MiqHostError.new "Missing credentials"
#    else
#      MiqException::MiqHostError.new "Unexpected response returned from system: #{err.message}"
#    end
     MiqException::MiqHostError.new "Unexpected response returned from system: #{err.message}"
  end

  def verify_credentials(auth_type=nil, options={})
    # TODO(erjohnso): add valid checks
    #raise MiqException::MiqHostError, "No credentials defined" if self.missing_credentials?(auth_type)

    begin
      # TODO(erjohnso): need to pass in connect options?
      with_provider_connection()
    rescue => err
      miq_exception = translate_exception(err)
      raise unless miq_exception

      _log.error("Error Class=#{err.class.name}, Message=#{err.message}")
      raise miq_exception
    end

    true
  end

  def gce
    @gce ||= connect(:service => "GCE", :service_endpoint => "compute", :service_version => "v1")
  end

  def s3
    @s3 ||= connect(:service => "S3", :service_endpoint => "compute", :service_version => "v1")
  end

  def sqs
    @sqs ||= connect(:service => "SQS", :service_endpoint => "compute", :service_version => "v1")
  end

  def cloud_formation
    @cloud_formation ||= connect(:service => "CloudFormation", :service_endpoint => "compute", :service_version => "v1")
  end

  #
  # Operations
  #

  def vm_start(vm, options = {})
    vm.start
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_stop(vm, options = {})
    vm.stop
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_destroy(vm, options = {})
    vm.vm_destroy
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_reboot_guest(vm, options = {})
    vm.reboot_guest
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def stack_create(stack_name, template, options = {})
    cloud_formation.stacks.create(stack_name, template.content, options).stack_id
  rescue => err
    _log.error "stack=[#{stack_name}], error: #{err}"
    raise MiqException::MiqOrchestrationProvisionError, err.to_s, err.backtrace
  end

  def stack_status(stack_name, _stack_id, _options = {})
    stack = cloud_formation.stacks[stack_name]
    return stack.status, stack.status_reason if stack
  rescue => err
    _log.error "stack=[#{stack_name}], error: #{err}"
    raise MiqException::MiqOrchestrationStatusError, err.to_s, err.backtrace
  end

  def orchestration_template_validate(template)
    cloud_formation.validate_template(template.content)[:message]
  rescue => err
    _log.error "template=[#{template.name}], error: #{err}"
    raise MiqException::MiqOrchestrationValidationError, err.to_s, err.backtrace
  end

  #
  # Discovery
  #

  # Factory method to create EmsGoogle instances for all instances
  #   or images for the given authentication.  Created EmsGoogle instances
  #   will automatically have EmsRefreshes queued up.  If this is a greenfield
  #   discovery, we will at least add an EmsGoogle for us-central1-f
  # TODO(erjohnso): fix method args - hacked to make empty strings
  def self.discover(access_key_id='', secret_access_key='')
    new_emses = []

    all_emses = includes(:authentications)
    all_ems_names = all_emses.index_by(&:name)

    known_emses = all_emses.select { |e| e.authentication_userid == access_key_id }
    # TODO(erjohnso): using 'zones' vs 'regions', re-purpose :provider_zone as the 'preferred' zone?
    known_ems_regions = known_emses.index_by(&:provider_region)

    gce = raw_connect(access_key_id, secret_access_key, "GCE")
    gce.regions.each do |region|
      next if known_ems_regions.include?(region.name)
      next if region.instances.count == 0 &&                 # instances
              region.images.with_owner(:self).count == 0 &&  # private images
              region.images.executable_by(:self).count == 0  # shared  images
      new_emses << create_discovered_region(region.name, access_key_id, secret_access_key, all_ems_names)
    end

    # If greenfield Google, at least create the us-central1-f zone.
    if new_emses.blank? && known_emses.blank?
      new_emses << create_discovered_region("us-central1-f", access_key_id, secret_access_key, all_ems_names)
    end

    EmsRefresh.queue_refresh(new_emses) unless new_emses.blank?

    new_emses
  end

  def self.discover_queue(access_key_id, secret_access_key)
    MiqQueue.put(
      :class_name  => self.name,
      :method_name => "discover_from_queue",
      :args        => [access_key_id, MiqPassword.encrypt(secret_access_key)]
    )
  end

  private

  def self.discover_from_queue(access_key_id, secret_access_key)
    discover(access_key_id, MiqPassword.decrypt(secret_access_key))
  end

  # TODO(erjohnso): fix method args -remove hack for auth empty strings
  def self.create_discovered_region(region_name, access_key_id='', secret_access_key='', all_ems_names)
    name = region_name
    name = "#{region_name} #{access_key_id}" if all_ems_names.has_key?(name)
    while all_ems_names.has_key?(name)
      name_counter = name_counter.to_i + 1 if defined?(name_counter)
      name = "#{region_name} #{name_counter}"
    end

    new_ems = self.create!(
      :name            => name,
      :provider_region => region_name,
      :zone            => Zone.default_zone
    )
    new_ems.update_authentication(
      :default => {
        :userid   => access_key_id,
        :password => secret_access_key
      }
    )

    new_ems
  end
end
