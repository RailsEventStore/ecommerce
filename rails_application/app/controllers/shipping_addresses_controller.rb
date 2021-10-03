class ShippingAddressesController < ApplicationController

  def new
    @order_id = params[:order_id]
  end

  def create
    cmd =
      Shipping::AddShippingAddressToShipment.new(
        order_id: params[:order_id],
        line_1: params[:line_1],
        line_2: params[:line_2],
        line_3: params[:line_3],
        line_4: params[:line_4],
      )
    ApplicationRecord.transaction { command_bus.(cmd) }
    redirect_to edit_order_path(params[:order_id]),
      notice: "Shippping Address was successfully updated"
  rescue Inventory::InventoryEntry::InventoryNotAvailable
    redirect_to order_path(Orders::Order.find_by_uid(cmd.order_id)),
      alert:
        "Order can not be submitted! Some products are not available"
  end
end
