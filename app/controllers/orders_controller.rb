class OrdersController < ApplicationController
  def index
    @orders = Order.all
  end

  def show
    @order = Order.find(params[:id])
    @order_lines = OrderLine.where(order_uid: @order.uid)
  end

  def new
    @order_id = SecureRandom.uuid
    @products = Product.all
    @customers = Customer.all
  end

  def add_item
    cmd = Command::AddItemToBasket.new(product_params)
    execute(cmd)

    head :ok
  end

  def remove_item
    cmd = Command::RemoveItemFromBasket.new(product_params)
    execute(cmd)

    head :ok
  end

  def create
    cmd = Command::SubmitOrder.new(order_params)
    execute(cmd)

    redirect_to Order.find_by_uid(cmd.order_id), notice: 'Order was successfully submitted.'
  end

  def expire
    ::Order.where(state: "Draft").find_each do |order|
      cmd = Command::SetOrderAsExpired.new(order_id: order.uid)
      execute(cmd)
    end

    redirect_to root_path
  end

  def history
    @order  = Order.find(params[:id])
    @stream = "Domain::Order$#{@order.uid}"
    @events = Rails.configuration.event_store.read.stream(@stream).backward
  end

  private
  def execute(cmd)
    Rails.configuration.command_bus.call(cmd)
  end

  def product_params
    args = params.permit(:id, :product_id)
    {order_id: args[:id], product_id: args[:product_id]}
  end

  def order_params
    params.permit(:order_id, :customer_id)
  end
end
