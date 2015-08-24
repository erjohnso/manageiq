class ManageIQ::Providers::Google::CloudManager::RefreshWorker < ManageIQ::Providers::BaseManager::RefreshWorker
  require_dependency 'manageiq/providers/google/cloud_manager/refresh_worker/runner'
end
