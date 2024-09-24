class OrdersController < ApplicationController
  def index
    @orders = Order.order("id DESC").page(params[:page]).per(10)
  end

  def show
    @order = Order.find_by(id: params[:id])

    return not_found unless @order

    @total = @order.total_after_discount
    @order_lines = @order.order_items
  end

  def new
    @order = Order.new
    @order.status = "Draft"
    @order.total = 0
    @order.discount = 0

    ApplicationRecord.transaction do
      @order.save!
      event_store.publish(Ordering::OrderCreated.new(data: { id: @order.id }), stream_name: "Ordering::Order$#{@order.id}")
    end
    @order_id = @order.id
    @products = Product.all
    @customers = Customer.all
    @time_promotions = TimePromotion.current
  end

  def edit
    @order_id = params[:id]
    @order = Order.find(params[:id])
    @products = Product.all
    @customers = Customer.all
    @time_promotions = TimePromotion.current
    discounted_value = @order.total_after_discount

    if @time_promotions.any?
      @time_promotions.sum(&:discount).tap do |discount|
        discounted_value -= (discounted_value * discount) / 100
      end
    end

    render :edit,
           locals: {
             discounted_value:,
             total_value: @order.total,
             percentage_discount: @order.discount
           }
  end

  def edit_discount
    @order_id = params[:id]
  end

  def update_discount
    order = Order.find(params[:id])
    order.discount = params[:amount]
    order.discount_updated_at = Time.current
    order.save!

    redirect_to edit_order_path(order)
  end

  def reset_discount
    order = Order.find(params[:id])
    order.discount = 0
    order.discount_updated_at = Time.current
    order.save!

    redirect_to edit_order_path(order)
  end

  def add_item
    product = Product.find(params[:product_id])
    if product.stock_level < 1
      redirect_to edit_order_path(params[:id]),
                  alert: "Product not available in requested quantity!" and return
    end

    @order = Order.find(params[:id])
    ApplicationRecord.transaction do
      @order.add_item(Product.find(params[:product_id]))
      Inventory::ProductService.new.decrement_stock_level(product.id)
      @order.save!
      event_store.publish(Ordering::ItemAdded.new(data: { order_id: @order.id, product_id: params[:product_id] }), stream_name: "Ordering::Order$#{@order.id}")
    end

    redirect_to edit_order_path(params[:id])
  end

  def remove_item
    product = Product.find(params[:product_id])
    @order = Order.find(params[:id])
    ApplicationRecord.transaction do
      @order.remove_item(product)
      Inventory::ProductService.new.increment_stock_level(product.id)
      @order.save!
      event_store.publish(Ordering::ItemRemoved.new(data: { order_id: @order.id, product_id: product.id }), stream_name: "Ordering::Order$#{@order.id}")
    end

    redirect_to edit_order_path(params[:id])
  end

  def create
    order = Order.find(params[:order_id])
    if order.order_items.empty?
      redirect_to order_path(order.id), alert: "Order cannot be submitted because it is empty"
      return
    end
    customer = Customer.find_by(id: params[:customer_id])
    unless customer
      redirect_to order_path(order.id), alert: "Order can not be submitted! Customer does not exist."
      return
    end
    ApplicationRecord.transaction { submit_order(order, params[:customer_id]) }
    redirect_to order_path(params[:order_id]), notice: "Your order is being submitted"
  end

  def expire
    Order
      .where(status: "Draft")
      .find_each do |order|
      order.order_items.each do |item|
        Inventory::ProductService.new.increment_stock_level(item.product.id)
      end
      order.status = "Expired"
      ApplicationRecord.transaction do
        order.save!
        event_store.publish(Ordering::OrderExpired.new(data: { id: order.id }), stream_name: "Ordering::Order$#{order.id}")
      end
    end
    redirect_to root_path
  end

  def pay
    order = Order.find(params[:id])

    if order.invoice_payment_status == "Authorized"
      flash[:alert] = "Payment was already authorized"
    elsif order.invoice_payment_status == "Captured"
      flash[:alert] = "Payment was already captured"

    else
      ActiveRecord::Base.transaction do
        order.invoice_payment_status = "Authorized"
        event_store.publish(Ordering::OrderPaid.new(data: { id: order.id }), stream_name: "Ordering::Order$#{order.id}")
        order.save!

        order.invoice_payment_status = "Captured"
        order.invoice_payment_date = Time.current
        order.status = "Paid"
        customer = order.customer
        customer.paid_orders_summary += order.total
        order.save!
        customer.save!

        flash[:notice] = "Order paid successfully"
      end
    end

    redirect_to orders_path
  end

  def cancel
    order = Order.find(params[:id])
    order.status = "Cancelled"
    order.save!
    redirect_to root_path, notice: "Order cancelled"
  end

  private

  def submit_order(order, customer_id)
    if order.status == "Draft"
      order.status = "Submitted"
      order.number = Time.now.strftime("%Y/%m/#{SecureRandom.random_number(100)}")
      order.customer_id = customer_id.to_i
      order.completed_at = Time.current
      event_store.publish(Ordering::OrderSubmitted.new(data: { id: order.id }), stream_name: "Ordering::Order$#{order.id}")
      order.save!
    end
  end

  def not_found
    render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
  end
end
