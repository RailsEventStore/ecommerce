class OrdersController < ApplicationController
  def index
    @orders = Orders::Order.order("id DESC").page(params[:page]).per(10)
  end

  def show
    @order = Orders::Order.find_by_uid(params[:id])
    @order_lines = Orders::OrderLine.where(order_uid: @order.uid)
    @shipment = Shipments::Shipment.find_by(order_uid: @order.uid)
    @invoice = Invoices::Invoice.find_or_initialize_by(order_uid: @order.uid)
  end

  def new
    redirect_to edit_order_path(SecureRandom.uuid)
  end

  def edit
    @order_id = params[:id]
    @order = Orders::Order.find_by_uid(params[:id])
    @order_lines = Orders::OrderLine.where(order_uid: params[:id])
    @products = Products::Product.all
    @customers = Customers::Customer.all
    @time_promotions = TimePromotions::TimePromotion.current

    render :edit,
           locals: {
             discounted_value: @order&.discounted_value || 0,
             total_value: @order&.total_value || 0,
             percentage_discount: @order&.percentage_discount
           }
  end

  def edit_discount
    @order_id = params[:id]
  end

  def update_discount
    @order_id = params[:id]
    if Orders::Order.find_by_uid(params[:id]).percentage_discount
      command_bus.(Pricing::ChangePercentageDiscount.new(order_id: @order_id, amount: params[:amount]))
    else
      command_bus.(Pricing::SetPercentageDiscount.new(order_id: @order_id, amount: params[:amount]))
    end

    redirect_to edit_order_path(@order_id)
  end

  def reset_discount
    @order_id = params[:id]
    command_bus.(Pricing::ResetPercentageDiscount.new(order_id: @order_id))

    redirect_to edit_order_path(@order_id)
  end

  def add_item
    read_model = Orders::OrderLine.where(order_uid: params[:id], product_id: params[:product_id]).first
    if Availability::Product.exists?(["uid = ? and available < ?", params[:product_id], (read_model&.quantity || 0) + 1])
      redirect_to edit_order_path(params[:id]),
                  alert: "Product not available in requested quantity!" and return
    end
    ActiveRecord::Base.transaction do
      command_bus.(Ordering::AddItemToBasket.new(order_id: params[:id], product_id: params[:product_id]))
    end
    head :ok
  end

  def remove_item
    command_bus.(Ordering::RemoveItemFromBasket.new(order_id: params[:id], product_id: params[:product_id]))
    head :ok
  rescue Ordering::Order::CannotRemoveZeroQuantityItem
    redirect_to edit_order_path(params[:id]), alert: "Cannot remove the product with 0 quantity"
  end

  def create
    ApplicationRecord.transaction { submit_order(params[:order_id], params[:customer_id]) }
    redirect_to order_path(params[:order_id]), notice: "Your order is being submitted"
  rescue Crm::Customer::NotExists
    redirect_to order_path(params[:order_id]), alert: "Order can not be submitted! Customer does not exist."
  end

  def expire
    Orders::Order
      .where(state: "Draft")
      .find_each { |order| command_bus.(Ordering::SetOrderAsExpired.new(order_id: order.uid)) }
    redirect_to root_path
  end

  def pay
    ActiveRecord::Base.transaction do
      authorize_payment(params[:id])
      capture_payment(params[:id])
      flash[:notice] = "Order paid successfully"
    rescue Payments::Payment::AlreadyAuthorized
      flash[:alert] = "Payment was already authorized"
    rescue Payments::Payment::AlreadyCaptured
      flash[:alert] = "Payment was already captured"
    rescue Payments::Payment::NotAuthorized
      flash[:alert] = "Payment wasn't yet authorized"
    rescue Ordering::Order::NotSubmitted
      flash[:alert] = "You can't pay for an order which is not submitted"
    end
    redirect_to orders_path
  end

  def cancel
    command_bus.(Ordering::CancelOrder.new(order_id: params[:id]))
    redirect_to root_path, notice: "Order cancelled"
  end

  private

  def submit_order(order_id, customer_id)
    command_bus.(Ordering::SubmitOrder.new(order_id: order_id))
    command_bus.(Crm::AssignCustomerToOrder.new(order_id: order_id, customer_id: customer_id))
  end

  def authorize_payment(order_id)
    command_bus.call(authorize_payment_cmd(order_id))
  end

  def capture_payment(order_id)
    command_bus.call(capture_payment_cmd(order_id))
  end

  def authorize_payment_cmd(order_id)
    Payments::AuthorizePayment.new(order_id: order_id)
  end

  def capture_payment_cmd(order_id)
    Payments::CapturePayment.new(order_id: order_id)
  end
end
