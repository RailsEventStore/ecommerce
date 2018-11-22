class OrdersController < ApplicationController
  def index
    @orders = Order.all
  end

  def show
    @order       = Order.find(params[:id])
    @order_lines = OrderLine.where(order_uid: @order.uid)
  end

  def new
    @order_id  = SecureRandom.uuid
    @products  = Product.all
    @customers = Customer.all
  end

  def add_item
    command_bus.(AddItemToBasket.new(product_params))
    head :ok
  end

  def remove_item
    command_bus.(RemoveItemFromBasket.new(product_params))
    head :ok
  end

  def create
    cmd = SubmitOrder.new(order_params)
    command_bus.(cmd)
    redirect_to Order.find_by_uid(cmd.order_id), notice: 'Order was successfully submitted.'
  end

  def expire
    Order.where(state: "Draft").find_each do |order|
      command_bus.(SetOrderAsExpired.new(order_id: order.uid))
    end
    redirect_to root_path
  end

  def history
    @order  = Order.find(params[:id])
    @stream = "Order$#{@order.uid}"
    @events = event_store.read.stream(@stream).backward
  end

  private

  def product_params
    args = params.permit(:id, :product_id)
    {order_id: args[:id], product_id: args[:product_id]}
  end

  def order_params
    params.permit(:order_id, :customer_id)
  end
end
