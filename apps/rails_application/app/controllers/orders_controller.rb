class OrdersController < ApplicationController
  def index
    @orders = Orders.paginated_orders(params[:page], current_store_id)
  end

  def show
    @order_header = OrderHeader.find_by_uid(params[:id])
    @order = Orders.find_order(params[:id])

    return not_found unless @order_header && @order
  end

  def new
    order_id = SecureRandom.uuid
    ActiveRecord::Base.transaction do
      command_bus.(Pricing::DraftOffer.new(order_id: order_id))
      command_bus.(Stores::RegisterOffer.new(order_id: order_id, store_id: current_store_id))
    end
    redirect_to edit_order_path(order_id)
  end

  def edit
    @order_id = params[:id]
    @order = Orders.find_order_in_store(params[:id], current_store_id)

    return not_found unless @order

    @products = Products.products_for_store(current_store_id)
    @customers = Customers.customers_for_store(current_store_id)
    @time_promotions = TimePromotions.current_time_promotions_for_store(current_store_id)

    render :edit,
           locals: {
             discounted_value: @order.discounted_value || 0,
             total_value: @order.total_value || 0,
             percentage_discount: @order.percentage_discount
           }
  end

  def edit_discount
    @order_id = params[:id]
  end

  def update_discount
    @order_id = params[:id]
    order = Orders.find_or_create_order(params[:id])
    if order.percentage_discount
      command_bus.(Pricing::ChangePercentageDiscount.new(order_id: @order_id, amount: params[:amount]))
    else
      command_bus.(Pricing::SetPercentageDiscount.new(order_id: @order_id, amount: params[:amount]))
    end

    redirect_to edit_order_path(@order_id)
  end

  def remove_discount
    @order_id = params[:id]
    command_bus.(Pricing::RemovePercentageDiscount.new(order_id: @order_id))

    redirect_to edit_order_path(@order_id)
  end

  def add_item
    read_model = Orders.find_order_line(order_uid: params[:id], product_id: params[:product_id])
    unless Availability.approximately_available?(params[:product_id], (read_model&.quantity || 0) + 1)
      redirect_to edit_order_path(params[:id]),
                  alert: "Product not available in requested quantity!" and return
    end
    price = Products.find_product(params[:product_id]).price
    ActiveRecord::Base.transaction do
      command_bus.(Pricing::AddPriceItem.new(order_id: params[:id], product_id: params[:product_id], price:))
    end
    head :ok
  end

  def remove_item
    command_bus.(Pricing::RemovePriceItem.new(order_id: params[:id], product_id: params[:product_id]))
    head :ok
  end

  def create
    Orders::SubmitService.new(params[:order_id], params[:customer_id]).call
  rescue Orders::OrderHasUnavailableProducts => e
    unavailable_products = e.unavailable_products.join(", ")
    redirect_to edit_order_path(params[:order_id]), alert: "Order can not be submitted! #{unavailable_products} not available in requested quantity!"
  rescue Pricing::Offer::IsEmpty
    redirect_to edit_order_path(params[:order_id]), alert: "You can't submit an empty order"
  rescue Crm::Customer::NotExists
    redirect_to order_path(params[:order_id]), alert: "Order can not be submitted! Customer does not exist."
  else
    redirect_to order_path(params[:order_id]), notice: "Your order is being submitted"
  end

  def expire
    OrderHeader.draft_orders.find_each { |order| command_bus.(Pricing::ExpireOffer.new(order_id: order.uid)) }
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
    rescue Fulfillment::Order::InvalidState
      flash[:alert] = "Order is not in a valid state for payment"
    end
    redirect_to orders_path
  end

  def cancel
    command_bus.(Fulfillment::CancelOrder.new(order_id: params[:id]))
    redirect_to root_path, notice: "Order cancelled"
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
