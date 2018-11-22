class Event < RailsEventStore::Event
  def data
    super.symbolize_keys
  end
end
