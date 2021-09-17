require 'aggregate_root'
require 'active_support/notifications'

module Infra
  class AggregateRootRepository
    def initialize(event_store = Rails.configuration.event_store)
      @repository = AggregateRoot::InstrumentedRepository.new(
        AggregateRoot::Repository.new(event_store),
        ActiveSupport::Notifications
      )
    end

    def with_aggregate(aggregate_class, aggregate_id, &block)
      @repository.with_aggregate(
        aggregate_class.new(aggregate_id),
        stream_name(aggregate_class, aggregate_id),
        &block
      )
    end

    def stream_name(aggregate_class, aggregate_id)
      "#{aggregate_class.name}$#{aggregate_id}"
    end
  end
end