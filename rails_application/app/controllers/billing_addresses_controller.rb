class BillingAddressesController < ApplicationController

  def edit
    @order = Order.find(params[:order_id])
  end

  def update
    @order = Order.find(params[:order_id])
    @order.update!(address_params)

    redirect_to @order.submitted? ? order_path(params[:order_id]) : edit_order_path(params[:order_id]),
                notice: "Billing Address was successfully updated"
  end

  private

  def address_params
    params.require(:order).permit(
      :invoice_tax_id_number,
      :invoice_addressed_to,
      :invoice_address,
      :invoice_city,
      :invoice_country
    )
  end
end
