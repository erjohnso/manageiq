# Instance Types for GCE.  These types can vary by zone, so we're starting
# with just a few placeholders for the first pass at adding GCE support
# to ManageIQ
#
module ManageIQ::Providers::Google::InstanceTypes
  # Types that are currently advertised for use
  AVAILABLE_TYPES = {
    "f1-micro" => {
      :default                 => true,
      :name                    => "f1-micro",
      :family                  => "General Purpose, shared-core",
      :description             => "Shared-core",
      :memory                  => 0.6.gigabyte,
      :vcpu                    => 1,
      :pd_only                 => true,
      :architecture            => [:x86_64],
      :virtualization_type     => [:kvm],
      :network_performance     => :low_to_moderate,
      :physical_processor      => "Intel Xeon Family",
      :processor_clock_speed   => 2.5, # GHz
    },

    "n1-standard-1" => {
      :name                    => "n1-standard-1",
      :family                  => "Standard General Purpose",
      :description             => "n1-standard-1",
      :memory                  => 3.75.gigabyte,
      :vcpu                    => 1,
      :pd_only                 => true,
      :architecture            => [:x86_64],
      :virtualization_type     => [:kvm],
      :network_performance     => :low_to_moderate,
      :physical_processor      => "Intel Xeon Family",
      :processor_clock_speed   => 2.75, # GHz
    },
  }

  # Types that are still advertised, but not recommended for new instances.
  DEPRECATED_TYPES = {
  }

  # Types that are no longer advertised
  DISCONTINUED_TYPES = {
  }

  def self.all
    AVAILABLE_TYPES.values + DEPRECATED_TYPES.values + DISCONTINUED_TYPES.values
  end

  def self.names
    AVAILABLE_TYPES.keys + DEPRECATED_TYPES.keys + DISCONTINUED_TYPES.keys
  end
end
