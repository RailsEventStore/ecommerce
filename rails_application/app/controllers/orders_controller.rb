class OrdersController < ApplicationController
  def index
    @orders =
      Orders::Order
        .order("id DESC")
        .page(params[:page])
        .per(10)
  end

  def show
    @order = Orders::Order.find_by_uid(params[:id])
    @order_lines = Orders::OrderLine.where(order_uid: @order.uid)
    @shipment = Shipments::Shipment.find_by(order_uid: @order.uid)
    @invoice = Invoices::Invoice.find_or_initialize_by(order_uid: @order.uid)
  end

  def new
    @order_id = SecureRandom.uuid
    @products = Products::Product.all
    @customers = Customers::Customer.all
  end

  def edit
    @order_id = params[:id]
    @order = Orders::Order.find_by_uid(params[:id])
    @order_lines = Orders::OrderLine.where(order_uid: params[:id])
    @products = Products::Product.all
    @customers = Customers::Customer.all
  end

  def edit_discount
    @order_id = params[:id]
  end

  def update_discount
    @order_id = params[:id]
    command_bus.(
      Pricing::SetPercentageDiscount.new(
        order_id: @order_id,
        amount: params[:amount]
      )
    )

    redirect_to edit_order_path(@order_id)
  end

  def reset_discount
    @order_id = params[:id]
    command_bus.(
      Pricing::ResetPercentageDiscount.new(
        order_id: @order_id
      )
    )

    redirect_to edit_order_path(@order_id)
  end

  def add_item
    ActiveRecord::Base.transaction do
      command_bus.(
        Ordering::AddItemToBasket.new(
          order_id: params[:id],
          product_id: params[:product_id]
        )
      )
    end
    redirect_to edit_order_path(params[:id])
  rescue Inventory::InventoryEntry::InventoryNotAvailable
    redirect_to edit_order_path(params[:id]),
                alert: "Product not available in requested quantity!"
  end

  def remove_item
    command_bus.(
      Ordering::RemoveItemFromBasket.new(
        order_id: params[:id],
        product_id: params[:product_id]
      )
    )
    redirect_to edit_order_path(params[:id])
  rescue Ordering::Order::CannotRemoveZeroQuantityItem
    redirect_to edit_order_path(params[:id]),
                alert: "Cannot remove the product with 0 quantity"
  end

  def create
    cmd =
      Ordering::SubmitOrder.new(
        order_id: params[:order_id],
        customer_id: params[:customer_id]
      )
    ApplicationRecord.transaction { command_bus.(cmd) }
    redirect_to order_path(cmd.order_id),
                notice: "Order was successfully submitted"
  rescue Inventory::InventoryEntry::InventoryNotAvailable
    redirect_to order_path(cmd.order_id),
                alert:
                  "Order can not be submitted! Some products are not available"
  end

  def expire
    Orders::Order
      .where(state: "Draft")
      .find_each do |order|
      command_bus.(Ordering::SetOrderAsExpired.new(order_id: order.uid))
    end
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

  private

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
