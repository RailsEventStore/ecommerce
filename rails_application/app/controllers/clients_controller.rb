class ClientsController < ApplicationController
  def index
    @clients = ClientOrders::Client.all
  end

  def login
    redirect_to client_orders_path(params[:client_id])
  end
end
