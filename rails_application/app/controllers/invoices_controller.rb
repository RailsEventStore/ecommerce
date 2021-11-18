class InvoicesController < ApplicationController
  def show
    @order = Orders::Order.find_by_uid(params[:id])
    @order_lines = Orders::OrderLine.where(order_uid: @order.uid)
  end
end