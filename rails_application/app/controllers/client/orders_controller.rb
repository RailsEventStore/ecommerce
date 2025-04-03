module Client
  class OrdersController < BaseController

    def index
      render html: ClientOrders::Rendering::OrdersList.build(view_context, cookies[:client_id]), layout: true
    end

    def new
      order_id = SecureRandom.uuid
      redirect_to edit_client_order_path(order_id)
    end

    def create
      Client::Orders::SubmitService.call(order_id: params[:order_id], customer_id: cookies[:client_id])
    rescue Orders::OrderHasUnavailableProducts => e
      unavailable_products = e.unavailable_products.join(", ")
      redirect_to edit_client_order_path(params[:order_id]), alert: "Order can not be submitted! #{unavailable_products} not available in requested quantity!"
    rescue Pricing::Offer::IsEmpty
      redirect_to edit_client_order_path(params[:order_id]), alert: "You can't submit an empty order"
    else
      redirect_to client_order_path(params[:order_id]), notice: "Your order is being submitted"
    end

    def show
      render html: ClientOrders::Rendering::ShowOrder.build(view_context, params[:id]), layout: true
    end

    def edit
      order_id = params[:id]
      render html: ClientOrders::Rendering::EditOrder.build(view_context, order_id), layout: true
    end

    def add_item
      read_model = ClientOrders::OrderLine.where(order_uid: params[:id], product_id: params[:product_id]).first
      unless Availability.approximately_available?(params[:product_id], (read_model&.product_quantity || 0) + 1)
        redirect_to edit_client_order_path(params[:id]),
                    alert: "Product not available in requested quantity!" and return
      end
      price = PublicOffer::Product.find(params[:product_id]).price
      ActiveRecord::Base.transaction do
        command_bus.(
          Pricing::AddPriceItem.new(
            order_id: params[:id],
            product_id: params[:product_id],
            price: price
          )
        )
      end
    end

    def remove_item
      command_bus.(
        Pricing::RemovePriceItem.new(
          order_id: params[:id],
          product_id: params[:product_id]
        )
      )
    end

    def use_coupon
      coupon = Coupons::Coupon.find_by!("lower(code) = ?", params[:coupon_code].downcase)
      ActiveRecord::Base.transaction do
        command_bus.(use_coupon_cmd(params[:id], coupon.uid, coupon.discount))
      end
      flash[:notice] = "Coupon applied!"
      redirect_to edit_client_order_path(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Coupon not found!"
      redirect_to edit_client_order_path(params[:id])
    rescue Pricing::NotPossibleToAssignDiscountTwice
      flash[:alert] = "Coupon already used!"
      redirect_to edit_client_order_path(params[:id])
    end

    private

    def use_coupon_cmd(order_id, coupon_id, discount)
      Pricing::UseCoupon.new(order_id: order_id, coupon_id: coupon_id, discount: discount)
    end
  end
end
