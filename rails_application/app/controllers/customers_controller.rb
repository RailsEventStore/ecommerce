class CustomersController < ApplicationController
  def index
    @customers = Customer.all
  end

  def new
    @customer = Customer.new
  end

  def create
    Customer.create!(customer_params)
    redirect_to customers_path, notice: "Customer was successfully created"
  end

  def update
    promote_to_vip(params[:id])
  rescue Crm::Customer::AlreadyVip
    redirect_to customers_path, notice: "Customer was marked as vip"
  else
    redirect_to customers_path, notice: "Customer was promoted to VIP"
  end

  def show
    @customer = Customer.find(params[:id])
    @customer_orders = @customer.orders.order(created_at: :desc)
                                .page(params[:page]).per(10)
  end

  private

  def customer_params
    params.require(:customer).permit(:first_name, :last_name, :email)
  end

  def promote_to_vip(customer_id)
    Customer.find(customer_id).promote_to_vip
  end
end
