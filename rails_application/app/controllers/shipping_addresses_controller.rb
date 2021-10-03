class ShippingAddressesController < ApplicationController

  def new
    @shipment = Shipments::Shipment.find_or_initialize_by(order_uid: params[:order_id])
  end

  def create
    cmd =
      Shipping::AddShippingAddressToShipment.new(
        order_id: params[:order_id],
        line_1: address_params[:address_line_1],
        line_2: address_params[:address_line_2],
        line_3: address_params[:address_line_3],
        line_4: address_params[:address_line_4],
      )
    ApplicationRecord.transaction { command_bus.(cmd) }
    redirect_to edit_order_path(params[:order_id]),
      notice: "Shippping Address was successfully updated"
  rescue Inventory::InventoryEntry::InventoryNotAvailable
    redirect_to order_path(Orders::Order.find_by_uid(cmd.order_id)),
      alert:
        "Order can not be submitted! Some products are not available"
  end

  private

  def address_params
    params.require(:shipments_shipment).permit(
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4
    )
  end
end
