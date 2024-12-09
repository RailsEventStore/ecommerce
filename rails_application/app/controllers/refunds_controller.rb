class RefundsController < ApplicationController
  def new
    @order = Orders::Order.find_by_uid(params[:order_id])
    @refund = Refunds::Refund.new
    @order_lines = Orders::OrderLine.where(order_uid: params[:order_id])
  end
end
