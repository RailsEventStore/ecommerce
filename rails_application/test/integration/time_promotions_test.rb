
require "test_helper"

class TimePromotionsTest < InMemoryRESIntegrationTestCase
  def test_happy_path
    post "/time_promotions", params: {
      label: "Last Minute June 2022",
      discount: "50",
      start_time: "2022-06-30 15:00:00 UTC",
      end_time: "2022-07-01 00:00:00 UTC"
    }
    follow_redirect!
    assert_response :success

    assert_select("p", "Time promotion was successfully created")

    post "/time_promotions", params: {
      label: "Black Monday July 2022",
      discount: "40",
      start_time: "2022-07-04 01:00:00 UTC",
      end_time: "2022-07-05 00:00:00 UTC"
    }
    follow_redirect!
    assert_response :success

    assert_select("p", "Time promotion was successfully created")

    TimePromotions::CreateTimePromotion.drain

    get "/time_promotions"
    assert_select("td", "Last Minute June 2022")
    assert_select("td", "50")
    assert_select("td", "2022-06-30 15:00:00 UTC")
    assert_select("td", "2022-07-01 00:00:00 UTC")

    assert_select("td", "Black Monday July 2022")
    assert_select("td", "40")
    assert_select("td", "2022-07-04 01:00:00 UTC")
    assert_select("td", "2022-07-05 00:00:00 UTC")
  end
end
