class ShipmentsController < ApplicationController
  def index
    @orders = Order.order("id DESC").page(params[:page]).per(10)
  end
end
