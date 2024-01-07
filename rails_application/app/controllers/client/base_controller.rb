module Client
  class BaseController < ApplicationController

    layout "client_panel"
    before_action :ensure_logged_in

    private

    def ensure_logged_in
      if ClientOrders::Client.find_by(uid: cookies[:client_id]).nil?
        redirect_to logout_path
        return
      end
    end
  end
end