require "test_helper"

class DealsIntegrationTest < InMemoryRESIntegrationTestCase
  def test_list_deals
    get "/deals"
    assert_response(:success)
  end

  def test_new_deal_form
    get "/deals/new"
    assert_response(:success)
  end

  def test_create_deal
    pipeline_id = create_pipeline("Sales")

    post "/deals", params: { deal: { name: "Big Deal", pipeline_id: pipeline_id } }
    follow_redirect!
    assert_select("td", "Big Deal")
  end

  def test_create_deal_with_all_fields
    pipeline_id = create_pipeline("Sales")

    post "/deals", params: {
      deal: {
        name: "Big Deal",
        pipeline_id: pipeline_id,
        value: "10000",
        expected_close_date: "2026-06-01"
      }
    }
    follow_redirect!
    assert_select("td", "Big Deal")
  end

  def test_show_deal
    pipeline_id = create_pipeline("Sales")
    deal_id = create_deal("Big Deal", pipeline_id)

    get "/deals/#{deal_id}"
    assert_response(:success)
    assert_select("h1", "Big Deal")
    assert_select("dd", "Sales")
  end

  def test_edit_deal
    pipeline_id = create_pipeline("Sales")
    deal_id = create_deal("Big Deal", pipeline_id)

    get "/deals/#{deal_id}/edit"
    assert_response(:success)
  end

  def test_update_deal
    pipeline_id = create_pipeline("Sales")
    add_stage(pipeline_id, "Negotiation")
    deal_id = create_deal("Big Deal", pipeline_id)

    patch "/deals/#{deal_id}", params: {
      deal: { value: "50000", expected_close_date: "2026-12-01", stage: "Negotiation" }
    }
    follow_redirect!
    assert_select("dd", "50000")
    assert_select("dd", "2026-12-01")
    assert_select("dd", "Negotiation")
  end

  private

  def create_pipeline(name)
    post "/pipelines", params: { pipeline: { name: name } }
    follow_redirect!
    Pipelines.all.last.uid
  end

  def add_stage(pipeline_id, stage_name)
    post "/pipelines/#{pipeline_id}/add_stage", params: { stage: { name: stage_name } }
    follow_redirect!
  end

  def create_deal(name, pipeline_id)
    post "/deals", params: { deal: { name: name, pipeline_id: pipeline_id } }
    follow_redirect!
    Deals.all.last.uid
  end
end
