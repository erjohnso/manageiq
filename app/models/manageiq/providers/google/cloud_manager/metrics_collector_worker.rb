class ManageIQ::Providers::Google::CloudManager::MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
  require_dependency 'manageiq/providers/google/cloud_manager/metrics_collector_worker/runner'

  self.default_queue_name = "google"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for Google"
  end
end
