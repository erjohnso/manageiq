class ManageIQ::Providers::Google::CloudManager::EventCatcher < ManageIQ::Providers::BaseManager::EventCatcher
  require_dependency 'manageiq/providers/google/cloud_manager/event_catcher/runner'
end
