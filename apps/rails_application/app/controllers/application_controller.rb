class ApplicationController < ActionController::Base
  around_action :set_time_zone
  before_action :ensure_current_store

  def event_store
    Rails.configuration.event_store
  end

  def command_bus
    Rails.configuration.command_bus
  end

  def not_found
    render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
  end

  helper_method :current_store_id, :available_stores

  private

  def set_time_zone(&block)
    Time.use_zone(cookies[:timezone], &block)
  end

  def ensure_current_store
    return if current_store_id.present?
    cookies[:current_store_id] = first_available_store_id
  end

  def current_store_id
    return cookies[:current_store_id] if store_exists?(cookies[:current_store_id])
    cookies[:current_store_id] = first_available_store_id
  end

  def available_stores
    @available_stores ||= Admin::Store.order(:created_at)
  end

  def first_available_store_id
    available_stores.first&.id
  end

  def store_exists?(store_id)
    return false if store_id.blank?
    available_stores.exists?(id: store_id)
  end
end
