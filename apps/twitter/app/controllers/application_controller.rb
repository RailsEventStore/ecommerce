class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def command_bus
    Rails.configuration.command_bus
  end

  def event_store
    Rails.configuration.event_store
  end

  def current_handle
    Accounts.handle_for(session[:account_id])
  end
  helper_method :current_handle

  private

  def require_sign_in
    redirect_to new_session_path unless current_handle
  end
end
