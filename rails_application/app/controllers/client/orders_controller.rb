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
                  notice: "Order was successfully submitted"
    rescue Inventory::InventoryEntry::InventoryNotAvailable
      redirect_to client_order_path(params[:order_id]),
                  alert:
                    "Order can not be submitted! Some products are not available"
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
      ActiveRecord::Base.transaction do
        command_bus.(
          Ordering::AddItemToBasket.new(
            order_id: params[:id],
            product_id: params[:product_id]
          )
        )
      end
      redirect_to edit_client_order_path(params[:id])
    rescue Inventory::InventoryEntry::InventoryNotAvailable
      redirect_to edit_client_order_path(params[:id]),
                  alert: "Product not available in requested quantity!"
    end

    def remove_item
      command_bus.(
        Ordering::RemoveItemFromBasket.new(
          order_id: params[:id],
          product_id: params[:product_id]
        )
      )
      redirect_to edit_client_order_path(params[:id])
    rescue Ordering::Order::CannotRemoveZeroQuantityItem
      redirect_to edit_client_order_path(params[:id]),
                  alert: "Cannot remove the product with 0 quantity"
    end

  end
end
