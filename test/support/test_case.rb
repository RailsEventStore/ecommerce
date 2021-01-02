module TestCase
  def arrange(stream, events)
    event_store.publish(events, stream_name: stream)
  end

  def act(stream, command)
    before = event_store.read.stream(stream).to_a
    command_bus.(command)
    after = event_store.read.stream(stream).to_a
    after.reject { |a| before.any? { |b| a.event_id == b.event_id } }
  end

  def assert_changes(actuals, expected)
    expects = expected.map(&:data)
    assert_equal(expects, actuals.map(&:data))
  end

  def assert_no_changes(actuals)
    assert_empty(actuals)
  end

  def event_store
    Rails.configuration.event_store
  end

  def command_bus
    Rails.configuration.command_bus
  end
end
