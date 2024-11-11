class ShipmentsController < ApplicationController
  def index
    @shipments =
      Shipments::Shipment
        .joins(:order)
        .includes(:order)
        .with_full_address
        .order(id: :desc)
        .page(params[:page])
        .per(10)
  end

  def show
    @shipment = Shipments::Shipment.find(params[:id])
    @shipment_items = @shipment.shipment_items.page(params[:page]).per(25)
  end
end
