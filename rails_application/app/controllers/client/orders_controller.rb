module Client
  class OrdersController < ApplicationController
    def index
      ClientOrders::HTMLRenderer.new(:list).render(self, params[:client_id])
    end

    def show
      @order = ClientOrders::Order.find_by(order_uid: params[:order_uid], client_uid: params[:client_id]).order
      @order_lines = Orders::OrderLine.where(order_uid: @order.uid)
    end
  end
end
