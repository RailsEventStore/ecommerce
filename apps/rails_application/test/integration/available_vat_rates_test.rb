require "test_helper"

class AvailableVatRatesTest < InMemoryRESIntegrationTestCase
  def test_happy_path
    register_store("Store 1")
    get "/available_vat_rates/new"
    assert_select "h1", "New VAT Rate"

    post "/available_vat_rates",
         params: {
           "authenticity_token" => "[FILTERED]",
           "code" => "10.0",
           "rate" => "10.0"
         }
    follow_redirect!

    assert_equal "VAT rate was successfully created", flash[:notice]
    assert_select "h1", "VAT Rates"

    delete "/available_vat_rates",
            params: {
              "vat_rate_code" => "10.0"
            }
    follow_redirect!

    assert_equal "VAT rate was successfully removed", flash[:notice]
  end

  def test_validation_blank_errors
    register_store("Store 1")
    post "/available_vat_rates",
         params: {
           "authenticity_token" => "[FILTERED]",
           "code" => "",
           "rate" => ""
         }
    assert_response :unprocessable_entity

    assert_select "h1", "New VAT Rate"
    assert_select "span", "Code can't be blank"
    assert_select "span", "Rate can't be blank"
  end

  def test_validation_rate_must_be_numeric
    register_store("Store 1")
    post "/available_vat_rates",
         params: {
           "authenticity_token" => "[FILTERED]",
           "code" => "test",
           "rate" => "not a number"
         }
    assert_response :unprocessable_entity
    assert_select "span", "Rate is not a number"
  end

  def test_vat_rate_already_exists
    register_store("Store 1")
    post "/available_vat_rates",
        params: {
          "authenticity_token" => "[FILTERED]",
          "code" => "10.0",
          "rate" => "10.0"
        }

    post "/available_vat_rates",
        params: {
          "authenticity_token" => "[FILTERED]",
          "code" => "10.0",
          "rate" => "10.0"
        }

    assert_response :unprocessable_entity
    assert_select "#alert", "VAT rate already exists"
  end
end
