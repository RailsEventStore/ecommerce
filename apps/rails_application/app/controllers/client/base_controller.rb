module Client
  class BaseController < ApplicationController

    layout "client_panel"
    before_action :ensure_logged_in

    helper_method :current_client_id

    private

    def current_client_id
      session[:client_id]
    end

    def ensure_logged_in
      if ClientOrders::Client.find_by(uid: session[:client_id]).nil?
        redirect_to logout_path
        return
      end
    end
  end
end
