class BillingAddressesController < ApplicationController

  def edit
    @invoice = Invoices::Invoice.find_or_initialize_by(order_uid: params[:order_id])
    @order = Shipments::Order.find_or_initialize_by(uid: params[:order_id])
  end

  def update
    cmd =
      Invoicing::SetBillingAddress.new(
        invoice_id: params[:order_id],
        tax_id_number: address_params[:tax_id_number],
        postal_address: {
          line_1: address_params[:address_line_1],
          line_2: address_params[:address_line_2],
          line_3: address_params[:address_line_3],
          line_4: address_params[:address_line_4]
        }
      )
    command_bus.(cmd)
    @order = Shipments::Order.find_or_initialize_by(uid: params[:order_id])
    redirect_to @order.submitted? ? order_path(params[:order_id]) : edit_order_path(params[:order_id]),
                notice: "Billing Address was successfully updated"
  end

  private

  def address_params
    params.require(:invoices_invoice).permit(
      :tax_id_number,
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4
    )
  end
end
