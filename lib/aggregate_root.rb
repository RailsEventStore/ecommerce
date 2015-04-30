module AggregateRoot
  def apply(event, new = true)
    send("apply_#{event.class.name.demodulize.tableize.singularize}", event)
    changes << event if new
  end

  def changes
    @changes ||= []
  end

  def rebuild(events)
    events.each { |event| apply(event, false) } if events
  end
end
