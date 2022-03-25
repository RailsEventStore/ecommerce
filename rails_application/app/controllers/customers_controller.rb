class CustomersController < ApplicationController
  def index
    @customers = Customers::Customer.all
  end

  def new
    @customer_id = SecureRandom.uuid
  end

  def create
    create_customer(params[:customer_id], params[:name])
  rescue Crm::Customer::AlreadyRegistered
    flash[:notice] = "Customer was already registered"
    render "new"
  else
    redirect_to customers_path, notice: "Customer was successfully created"
  end

  def update
    promote_to_vip(params[:id])
  rescue Crm::Customer::AlreadyVip
    redirect_to customers_path, notice: "Customer was marked as vip"
  else
    redirect_to customers_path, notice: "Customer was promoted to VIP"
  end

  private

  def create_customer(customer_id, name)
    command_bus.(create_customer_cmd(customer_id, name))
  end

  def promote_to_vip(customer_id)
    command_bus.(promote_to_vip_cmd(customer_id))
  end

  def create_customer_cmd(customer_id, name)
    Crm::RegisterCustomer.new(customer_id: customer_id, name: name)
  end

  def promote_to_vip_cmd(customer_id)
    Crm::PromoteCustomerToVip.new(customer_id: customer_id)
  end
end
