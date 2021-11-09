class CustomerRepository
  def find(customer_id)
    Customers::Customer.where(id: customer_id).first
  end

  def all
    Customers::Customer.all
  end
end