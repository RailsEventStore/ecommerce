class ClientOrdersController < ApplicationController
  def index
    @clients = ClientOrders::Client.all
  end

  def show
    @client = ClientOrders::Client.find_by(uid: params[:id])
    @client_orders = ClientOrders::Order.where(client_uid: params[:id])
  end

  def login
    redirect_to action: 'show', id: params[:client_id]
  end
end
