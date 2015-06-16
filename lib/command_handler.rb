module CommandHandler
  def with_aggregate(aggregate_id)
    aggregate = build(aggregate_id)
    yield aggregate
    repository.store(aggregate)
  end

  private
  def build(aggregate_id)
    aggregate_class.new(aggregate_id).tap do |aggregate|
      repository.load(aggregate)
    end
  end

  def repository
    @repository ||= RailsEventStore::Repositories::AggregateRepository.new(event_store)
  end

  def event_store
    @event_store ||= RailsEventStore::Client.new.tap do |es|
      es.subscribe(Denormalizers::OrderCreated.new, ['Events::OrderCreated'])
      es.subscribe(Denormalizers::OrderExpired.new, ['Events::OrderExpired'])
      es.subscribe(Denormalizers::ItemAddedToBasket.new, ['Events::ItemAddedToBasket'])
      es.subscribe(Denormalizers::ItemRemovedFromBasket.new, ['Events::ItemRemovedFromBasket'])
    end
  end
end
