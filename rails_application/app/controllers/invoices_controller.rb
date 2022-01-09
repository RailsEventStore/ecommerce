class InvoicesController < ApplicationController
  def show
    @invoice = Invoices::Invoice.find_by_order_uid(params[:id])
  end

  def create
    begin
      ActiveRecord::Base.transaction do
        command_bus.(Invoicing::IssueInvoice.new(invoice_id: params[:order_id], issue_date: Time.zone.now.to_date))
      end
    rescue Invoicing::Invoice::BillingAddressNotSpecified
      flash[:alert] = "Billing address is missing"
    rescue Invoicing::Invoice::InvoiceAlreadyIssued
      flash[:alert] = "Invoice was already issued"
    rescue Invoicing::Invoice::InvoiceNumberInUse
      retry
    end
    redirect_to(invoice_path(params[:order_id]))
  end
end