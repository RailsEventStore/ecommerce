class ClientsController < ApplicationController
  layout "client_panel"

  def index
    @clients = ClientOrders::Client.all
  end

  def login
    cookies[:client_id] = params[:client_id]
    redirect_to client_orders_path
  end
end
