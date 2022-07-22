module Client
  class OrdersController < ApplicationController
    def index
      @client = ClientOrders::Client.find_by(uid: params[:client_id])
      @client_orders = ClientOrders::Order.includes(:order).where(client_uid: params[:client_id])
    end

    def show
      @order = ClientOrders::Order.find_by(order_uid: params[:order_uid], client_uid: params[:client_id]).order
      @order_lines = Orders::OrderLine.where(order_uid: @order.uid)
    end
  end
end
