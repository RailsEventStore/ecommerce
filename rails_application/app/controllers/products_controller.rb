class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
  end

  def edit
    @product = Product.find(params[:id])
  end

  def create
    Product.create!(product_params)
    redirect_to products_path, notice: "Product was successfully created"
  end

  def update
    @product = Product.find(params[:id])

    if params["future_price"].present?
      @product.future_price = params["future_price"]["price"]
      @product.future_price_start_time = params["future_price"]["start_time"]
      @product.save!
    else
      ActiveRecord::Base.transaction do
        @product_with_new_price = @product.dup
        @product_with_new_price.price = product_params[:price]
        @product_with_new_price.latest = true
        @product.latest = false
        @product_with_new_price.save!
        @product.save!
      end
    end
    redirect_to products_path, notice: "Product was successfully updated"
  end

  def add_future_price
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream:
                 turbo_stream.update(
                   "future_prices",
                   partial: "/products/future_price",
                   locals: {
                     disabled: false,
                     valid_since: nil,
                     price: nil
                   }
                 )
      end
    end
  end

  private

  def product_params
    params.require(:product).permit(:name, :price, :vat_rate, :sku).to_h.symbolize_keys.slice(:price, :vat_rate, :name, :sku)
  end
end
