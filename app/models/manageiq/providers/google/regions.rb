# The google-api-client gem can get us this information, however it talks to
# GCE to get it. For cases where we don't yet want to contact GCE, this
# information is hardcoded.

module ManageIQ
  module Providers::Google
    module Regions
      # From https://cloud.google.com/compute/docs/zones
      REGIONS = {
        "us-central1" => {
          :name        => "us-central1",
          :hostname    => "us-central1",
          :description => "Central US",
        },
        "europe-west1" => {
          :name        => "europe-west1",
          :hostname    => "europe-west1",
          :description => "Western Europe",
        },
        "asia-east1" => {
          :name        => "asia-east1",
          :hostname    => "asia-east1",
          :description => "East Asia",
        },
      }

      # TODO(erjohnso): hack to make GCE more compatible with other providers
      REGIONS_BY_HOSTNAME =
        REGIONS.values.each_with_object({}) do |v, h|
          h[v[:hostname]] = v
        end

      def self.all
        REGIONS.values
      end

      def self.names
        REGIONS.keys
      end

      def self.hostnames
        REGIONS_BY_HOSTNAME.keys
      end

      def self.find_by_name(name)
        REGIONS[name]
      end

      def self.find_by_hostname(hostname)
        REGIONS_BY_HOSTNAME[hostname]
      end
    end
  end
end
