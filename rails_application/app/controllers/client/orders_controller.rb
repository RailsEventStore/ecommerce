module Client
  class OrdersController < ApplicationController

    layout 'client_panel'

    def index
      render html: ClientOrders::OrdersList.build(view_context, cookies[:client_id]), layout: true
    end

    def new
      @order_id = SecureRandom.uuid
      @products = ClientOrders::Product.all
      render 'edit'
    end

    def create
      command_bus.(Ordering::SubmitOrder.new(order_id: params[:order_id]))
      command_bus.(Crm::AssignCustomerToOrder.new(customer_id: cookies[:client_id], order_id: params[:order_id]))
      redirect_to client_order_path(params[:order_id]),
                  notice: "Your order is being submitted"
    end

    def show
      @order = ClientOrders::Order.find_by_order_uid(params[:id])
      @order_lines = ClientOrders::OrderLine.where(order_uid: params[:id])
    end

    def edit
      @order_id = params[:id]
      @order_lines = ClientOrders::OrderLine.where(order_uid: params[:id])
      @products = ClientOrders::Product.all
    end

    def add_item
      read_model = ClientOrders::OrderLine.where(order_uid: params[:id], product_id: params[:product_id]).first
      if Availability::Product.exists?(["uid = ? and available < ?", params[:product_id], (read_model&.product_quantity || 0) + 1])
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
    rescue Ordering::Order::CannotRemoveZeroQuantityItem
      redirect_to edit_client_order_path(params[:id]),
                  alert: "Cannot remove the product with 0 quantity"
    end

  end
end
