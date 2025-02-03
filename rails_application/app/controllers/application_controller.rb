class ApplicationController < ActionController::Base
  around_action :set_time_zone

  def event_store
    Rails.configuration.event_store
  end

  def command_bus
    Rails.configuration.command_bus
  end

  def not_found
    render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
  end

  private

  def set_time_zone(&block)
    Time.use_zone(cookies[:timezone], &block)
  end
end
