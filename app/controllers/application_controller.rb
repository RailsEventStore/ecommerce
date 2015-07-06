class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include Command::Execute

  protected
  def dependencies
    {
      repository:       RailsEventStore::Repositories::AggregateRepository.new(event_store),
      number_generator: Domain::Services::NumberGenerator.new
    }
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
