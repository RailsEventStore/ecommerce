class SingleTableReadModel

  def initialize(event_store, active_record_name, id_column)
    @event_store = event_store
    @active_record_name = active_record_name
    @id_column = id_column
  end

  def subscribe_create(creation_event)
    @event_store.subscribe(-> (event) { create_record(event, @id_column) }, to: [creation_event])
  end

  def copy(event, attribute)
    @event_store.subscribe(-> (event) { copy_event_attribute_to_column(event, attribute, attribute) }, to: [event])
  end

  def copy_nested_to_column(event, top_event_attribute, nested_attribute, column)
    @event_store.subscribe(
      -> (event) { copy_nested_event_attribute_to_column(event, top_event_attribute, nested_attribute, column) }, to: [event])
  end

  def create_record(event, id_column)
    @active_record_name.create(id: event.data.fetch(id_column))
  end

  def copy_event_attribute_to_column(event, event_attribute, column)
    find_record(event).update_attribute(column, event.data.fetch(event_attribute))
  end

  def copy_nested_event_attribute_to_column(event, top_event_attribute, nested_attribute, column)
    find_record(event).update_attribute(column, event.data.fetch(top_event_attribute).fetch(nested_attribute))
  end

  def find_record(event)
    find(event.data.fetch(@id_column))
  end

  def find(id)
    @active_record_name.where(id: id).first
  end
end