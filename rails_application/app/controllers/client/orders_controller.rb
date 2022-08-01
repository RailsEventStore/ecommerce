module Client
  class OrdersController < ApplicationController

    layout 'client_panel'

    def index
      render html: ClientOrders::OrdersList.build(view_context, cookies[:client_id]), layout: true
    end


    def show
      @order = ClientOrders::Order.find_by(order_uid: params[:order_uid], client_uid: params[:client_id]).order
      @order_lines = Orders::OrderLine.where(order_uid: @order.uid)
    end
  end
end
