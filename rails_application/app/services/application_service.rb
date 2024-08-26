class ApplicationService
  def self.call(...)
    new(...).call
  end

  def call
    raise NotImplementedError
  end

  def event_store
    Rails.configuration.event_store
  end

  def command_bus
    Rails.configuration.command_bus
  end
end
