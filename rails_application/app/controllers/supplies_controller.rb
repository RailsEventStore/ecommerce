class SuppliesController < ApplicationController
  def new
    @product_id = params[:product_id]
  end

  def create
    product = Product.find(params[:product_id])
    product.stock_level == nil ? product.stock_level = params[:quantity].to_i : product.stock_level += params[:quantity].to_i
    product.save!
    redirect_to products_path, notice: "Stock level changed"
  end
end
