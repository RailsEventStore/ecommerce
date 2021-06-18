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
    @products  = ProductCatalog::Product.all
    @customers = Customer.all
  end

  def edit
    @order_id    = params[:id]
    @order       = Orders::Order.find_by_uid(params[:id])
    @order_lines = Orders::OrderLine.where(order_uid: params[:id])
    @products    = ProductCatalog::Product.all
    @customers   = Customer.all
  end

  def add_item
    command_bus.(Pricing::AddItemToBasket.new(order_id: params[:id], product_id: params[:product_id]))
    redirect_to edit_order_path(params[:id])
  end

  def remove_item
    command_bus.(Pricing::RemoveItemFromBasket.new(order_id: params[:id], product_id: params[:product_id]))
    redirect_to edit_order_path(params[:id])
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

  def pay
    ActiveRecord::Base.transaction do
      transaction_id = SecureRandom.hex(16)
      authorize_payment(params[:id], transaction_id)
      capture_payment(transaction_id)
      flash[:notice] = "Order paid successfully."
    rescue Payments::Payment::AlreadyAuthorized
      flash[:notice] = "Payment was already authorized."
    rescue Payments::Payment::AlreadyCaptured
      flash[:notice] = "Payment was already captured."
    rescue Payments::Payment::NotAuthorized
      flash[:notice] = "Payment wasn't yet authorized."
    rescue Ordering::Order::NotSubmitted
      flash[:notice] = "You can't pay for an order which is not submitted"
    end
    redirect_to orders_path
  end

  private

  def authorize_payment(order_id, transaction_id)
    command_bus.call(authorize_payment_cmd(order_id, transaction_id))
  end

  def capture_payment(transaction_id)
    command_bus.call(capture_payment_cmd(transaction_id))
  end

  def authorize_payment_cmd(order_id, transaction_id)
    Payments::AuthorizePayment.new(
      order_id: order_id,
      transaction_id: transaction_id
    )
  end

  def capture_payment_cmd(transaction_id)
    Payments::CapturePayment.new(transaction_id: transaction_id)
  end
end
