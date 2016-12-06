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

  private
  def product_params
    args = params.permit(:id, :product_id)
    {order_id: args[:id], product_id: args[:product_id]}
  end

  def order_params
    params.permit(:order_id, :customer_id)
  end
end
