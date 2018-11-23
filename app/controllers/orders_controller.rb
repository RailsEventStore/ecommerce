class OrdersController < ApplicationController
  def index
    @orders = Orders::Order.all
  end

  def show
    @order       = Orders::Order.find(params[:id])
    @order_lines = Orders::OrderLine.where(order_uid: @order.uid)
  end

  def new
    @order_id  = SecureRandom.uuid
    @products  = Product.all
    @customers = Customer.all
  end

  def add_item
    command_bus.(Ordering::AddItemToBasket.new(order_id: params[:id], product_id: params[:product_id]))
    head :ok
  end

  def remove_item
    command_bus.(Ordering::RemoveItemFromBasket.new(order_id: params[:id], product_id: params[:product_id]))
    head :ok
  end

  def create
    cmd = Ordering::SubmitOrder.new(order_id: params[:order_id], customer_id: params[:customer_id])
    command_bus.(cmd)
    redirect_to order_path(Orders::Order.find_by_uid(cmd.order_id)), notice: 'Order was successfully submitted.'
  end

  def expire
    Orders::Order.where(state: "Draft").find_each do |order|
      command_bus.(Ordering::SetOrderAsExpired.new(order_id: order.uid))
    end
    redirect_to root_path
  end
end
