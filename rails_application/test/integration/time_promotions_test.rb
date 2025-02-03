
require "test_helper"

class TimePromotionsTest < InMemoryRESIntegrationTestCase
  def test_happy_path
    cookies[:timezone] = "Europe/Warsaw"

    post "/time_promotions", params: {
      label: "Last Minute June 2022",
      discount: "50",
      start_time: "2022-06-30 15:00",
      end_time: "2022-07-01 00:00"
    }
    follow_redirect!
    assert_response :success

    time_promotion = TimePromotions::TimePromotion.find_by(label: "Last Minute June 2022")

    assert_equal("2022-06-30 13:00:00 UTC", time_promotion.start_time.to_s)
    assert_equal("2022-06-30 22:00:00 UTC", time_promotion.end_time.to_s)

    assert_select("p", "Time promotion was successfully created")

    post "/time_promotions", params: {
      label: "Black Monday July 2022",
      discount: "40",
      start_time: "2022-07-04 01:00:00",
      end_time: "2022-07-05 00:00:00"
    }
    follow_redirect!
    assert_response :success

    time_promotion = TimePromotions::TimePromotion.find_by(label: "Black Monday July 2022")

    assert_equal("2022-07-03 23:00:00 UTC", time_promotion.start_time.to_s)
    assert_equal("2022-07-04 22:00:00 UTC", time_promotion.end_time.to_s)

    assert_select("p", "Time promotion was successfully created")

    get "/time_promotions"
    assert_select("td", "Last Minute June 2022")
    assert_select("td", "50")
    assert_select("td", "2022-06-30 15:00:00 +0200")
    assert_select("td", "2022-07-01 00:00:00 +0200")

    assert_select("td", "Black Monday July 2022")
    assert_select("td", "40")
    assert_select("td", "2022-07-04 01:00:00 +0200")
    assert_select("td", "2022-07-05 00:00:00 +0200")
  end
end
