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
  rescue ActiveRecord::RecordInvalid => e
    return render :new, status: :unprocessable_entity, locals: { errors: e.record.errors }
  end

  def update
    @product = Product.find(params[:id])

    @product.change_name(params[:product][:name])
    @product.change_price!(product_params)

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
