class SuppliesController < ApplicationController
  def new
    @product_id = params[:product_id]
  end

  def create
    Inventory::ProductService.new.supply(Inventory::SupplyStockLevel.new(params[:product_id], params[:quantity]))
    redirect_to products_path, notice: "Stock level changed"
  end
end
