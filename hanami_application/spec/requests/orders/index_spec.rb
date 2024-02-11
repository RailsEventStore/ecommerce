# frozen_string_literal: true

RSpec.describe "Submit Order", type: :request do
  it "is successful" do
    # Arrange
    # Act
    get "/"

    # Assert
    expect(last_response).to be_successful
  end
end
