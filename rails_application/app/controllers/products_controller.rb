class ProductsController < ApplicationController
  def index
    @products = Product.joins(:product_catalog).select("products.id, products.name, products.price, products.vat_rate, products.sku, product_catalogs.stock_level")
  end

  def show
    @product = Product
                 .where(id: params[:id])
                 .joins(:product_catalog)
                 .select("products.id, products.name, products.price, products.vat_rate, products.sku, product_catalogs.stock_level")
                 .first
  end

  def new
    @product = Product.new
  end

  def edit
    @product = Product.find(params[:id])
  end

  def create
    ApplicationRecord.transaction do
      product = Product.create!(product_params)
      event_store.publish(ProductCatalog::ProductCreated.new(data: product_params.merge(id: product.id)), stream_name: "ProductCatalog::Product$#{product.id}")
    end
    redirect_to products_path, notice: "Product was successfully created"
  rescue ActiveRecord::RecordInvalid => e
    return render :new, status: :unprocessable_entity, locals: { errors: e.record.errors }
  end

  def update
    @product = Product.find(params[:id])
    begin
      ApplicationRecord.transaction do
        if params["future_price"].present?
          @product.future_price = params["future_price"]["price"]
          @product.future_price_start_time = params["future_price"]["start_time"]
          @product.save!
        end
        if !!product_params[:name] && @product.name != product_params[:name]
          event_store.publish(ProductCatalog::ProductNameChanged.new(data: { id: @product.id, name: product_params[:name] }), stream_name: "ProductCatalog::Product$#{@product.id}")
        elsif !!product_params[:price] && @product.price != product_params[:price]
          event_store.publish(ProductCatalog::ProductPriceChanged.new(data: { id: @product.id, price: product_params[:price].to_d }), stream_name: "ProductCatalog::Product$#{@product.id}")
        end
        @product.update!(product_params)
      end
      redirect_to products_path, notice: "Product was successfully updated"
    rescue ActiveRecord::StaleObjectError
      head :conflict
    end
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
    params.require(:product).permit(:name, :price, :vat_rate, :sku, :version).to_h.symbolize_keys.slice(:price, :vat_rate, :name, :sku, :version)
  end

  def event_store
    Rails.configuration.event_store
  end
end
