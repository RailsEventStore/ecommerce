class ShipmentsController < ApplicationController
  def index
    @shipments =
      Shipments::Shipment
        .includes(:order)
        .order("id DESC")
        .page(params[:page])
        .per(10)
  end
end
