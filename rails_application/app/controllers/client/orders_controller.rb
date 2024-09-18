module Client
  class OrdersController < BaseController

    def index
      render html: ClientOrders::OrdersList.build(view_context, cookies[:client_id]), layout: true
    end

    def new
      order_id = SecureRandom.uuid
      redirect_to edit_client_order_path(order_id)
    end

    def create
      Client::Orders::SubmitService.call(order_id: params[:order_id], customer_id: cookies[:client_id])
    rescue Orders::OrderHasUnavailableProducts => e
      unavailable_products = e.unavailable_products.join(", ")
      redirect_to edit_client_order_path(params[:order_id]), alert: "Order can not be submitted! #{unavailable_products} not available in requested quantity!"
    rescue Ordering::Order::IsEmpty
      redirect_to edit_client_order_path(params[:order_id]), alert: "You can't submit an empty order"
    else
      redirect_to client_order_path(params[:order_id]), notice: "Your order is being submitted"
    end

    def show
      @order = ClientOrders::Order.find_by_order_uid(params[:id])
      @order_lines = ClientOrders::OrderLine.where(order_uid: params[:id])
      render html: ClientOrders::ShowOrder.build(view_context, @order, @order_lines), layout: true
    end

    def edit
      order_id = params[:id]
      order_lines = ClientOrders::OrderLine.where(order_uid: params[:id])
      products = ClientOrders::Product.all
      render html: ClientOrders::EditOrder.build(view_context, order_id, order_lines, products), layout: true
    end

    def add_item
      read_model = ClientOrders::OrderLine.where(order_uid: params[:id], product_id: params[:product_id]).first
      unless Availability.approximately_available?(params[:product_id], (read_model&.product_quantity || 0) + 1)
        redirect_to edit_client_order_path(params[:id]),
                    alert: "Product not available in requested quantity!" and return
      end
      ActiveRecord::Base.transaction do
        command_bus.(
          Ordering::AddItemToBasket.new(
            order_id: params[:id],
            product_id: params[:product_id]
          )
        )
      end
    end

    def remove_item
      command_bus.(
        Ordering::RemoveItemFromBasket.new(
          order_id: params[:id],
          product_id: params[:product_id]
        )
      )
    end

  end
end
