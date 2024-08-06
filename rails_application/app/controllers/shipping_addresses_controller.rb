class ShippingAddressesController < ApplicationController

  def edit
    @order = Order.find(params[:order_id])
  end

  def update
    @order = Order.find(params[:order_id])

    @order.update!(address_params)

    redirect_to @order.submitted? ? order_path(params[:order_id]) : edit_order_path(params[:order_id]),
                notice: "Shippping Address was successfully updated"
  end

  private

  def address_params
    params.require(:order).permit(
      :addressed_to,
      :address,
      :city,
      :country
    )
  end
end
