class OrdersController < ApplicationController
  # GET /orders
  # GET /orders.json
  def index
    @orders = Order.all
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @order = Order.find(params[:id])
    @order_lines = OrderLine.where(order_uid: @order.uid)
  end

  # GET /orders/new
  def new
    @order_id = SecureRandom.uuid
    @products = Product.all
    @customers = Customer.all
  end

  # POST /orders/:id/add_item
  def add_item
    cmd = Command::AddItemToBasket.new(product_params)
    execute(cmd)

    head :ok
  end

  # POST /orders/:id/remove_item
  def remove_item
    cmd = Command::RemoveItemFromBasket.new(product_params)
    execute(cmd)

    head :ok
  end

  # POST /orders
  # POST /orders.json
  def create
    cmd = Command::CreateOrder.new(order_params)
    execute(cmd)

    redirect_to Order.find_by_uid(cmd.order_id), notice: 'Order was successfully created.'
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
