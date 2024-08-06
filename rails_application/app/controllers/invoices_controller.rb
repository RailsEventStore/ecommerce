class InvoicesController < ApplicationController
  def show
    @invoice = Order.find(params[:id])
    @discount = @invoice.discount == 0 ? 1 : @invoice.discount
    time_promotions = TimePromotion.where("start_time <= ? AND end_time >= ?", @invoice.completed_at, @invoice.invoice_issue_date)
    if time_promotions.any?
      time_promotions.sum(&:discount).tap do |time_promotion_discount|
        @discount += time_promotion_discount
      end
    end
  end

  def create
    @order = Order.find(params[:order_id])

    if !@order.billing_address_specified?
      flash[:alert] = "Billing address is missing"
    elsif @order.invoice_issued?
      flash[:alert] = "Invoice was already issued"
    else
      @order.invoice_issued = true
      @order.invoice_issue_date = Time.current
      invoice_total_value = @order.total - ((@order.total * @order.discount) / 100)
      time_promotions = TimePromotion.current

      if time_promotions.any?
        time_promotions.sum(&:discount).tap do |discount|
          invoice_total_value -= (invoice_total_value * discount) / 100
        end
      end
      @order.invoice_total_value = invoice_total_value
      @order.save!
    end

    redirect_to(invoice_path(params[:order_id]))
  end
end