class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def execute(command)
    command.validate!
    handler = "CommandHandlers::#{command.class.name.demodulize}"
    handler.constantize.new(repository).call(command)
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
