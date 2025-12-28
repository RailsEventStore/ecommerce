class CustomersController < ApplicationController
  def index
    @customers = Customers.customers_for_store(current_store_id)
  end

  def new
    @customer_id = SecureRandom.uuid
  end

  def create
    ActiveRecord::Base.transaction do
      create_customer(params[:customer_id], params[:name])
    end
  rescue Crm::Customer::AlreadyRegistered
    flash[:notice] = "Customer was already registered"
    render "new"
  else
    redirect_to customers_path, notice: "Customer was successfully created"
  end

  def update
    customer = Customers.find_customer_in_store(params[:id], current_store_id)
    promote_to_vip(customer.id)
  rescue Crm::Customer::AlreadyVip
    redirect_to customers_path, notice: "Customer was marked as vip"
  else
    redirect_to customers_path, notice: "Customer was promoted to VIP"
  end

  def show
    @customer = Customers.find_customer_in_store(params[:id], current_store_id)
    @customer_orders = ClientOrders::Order.where(client_uid: params[:id])
                                          .order(created_at: :desc)
                                          .page(params[:page]).per(10)
  end

  private

  def create_customer(customer_id, name)
    command_bus.(create_customer_cmd(customer_id, name))
    command_bus.(register_customer_in_store_cmd(customer_id))
  end

  def promote_to_vip(customer_id)
    command_bus.(promote_to_vip_cmd(customer_id))
  end

  def create_customer_cmd(customer_id, name)
    Crm::RegisterCustomer.new(customer_id: customer_id, name: name)
  end

  def register_customer_in_store_cmd(customer_id)
    Stores::RegisterCustomer.new(customer_id: customer_id, store_id: current_store_id)
  end

  def promote_to_vip_cmd(customer_id)
    Crm::PromoteCustomerToVip.new(customer_id: customer_id)
  end
end
