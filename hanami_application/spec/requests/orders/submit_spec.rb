# frozen_string_literal: true

RSpec.describe "Submit Order", type: :request do
  it "is successful" do
    # Arrange
    order_id = SecureRandom.uuid
    customer_id = SecureRandom.uuid

    Hanami.app["ecommerce.config"]
    Hanami.app["command_bus"].(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'Bruce Wayne'))

    # Act
    post "/orders", { order_id: order_id, customer_id: customer_id}

    # Assert
    response_uuid = JSON.parse(last_response.body)["uuid"]
    expect(response_uuid).to eq(order_id)

    expect(last_response).to be_successful
  end
end
