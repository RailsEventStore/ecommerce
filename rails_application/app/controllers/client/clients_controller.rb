module Client
  class ClientsController < ApplicationController
    layout "client_panel"

    def index
      if cookies[:client_id]
        redirect_to client_orders_path
      else
        render html: Login.build(view_context), layout: true
      end
    end

    def login
      cookies[:client_id] = params[:client_id]
      redirect_to client_orders_path
    end

    def logout
      cookies.delete(:client_id)
      redirect_to clients_path
    end
  end
end
