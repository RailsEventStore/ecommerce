class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  def command_bus
    Rails.configuration.command_bus
  end

  def event_store
    Rails.configuration.event_store
  end
end
