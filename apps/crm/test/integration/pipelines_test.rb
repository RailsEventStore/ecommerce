require "test_helper"

class PipelinesIntegrationTest < InMemoryRESIntegrationTestCase
  def test_list_pipelines
    get "/pipelines"
    assert_response(:success)
  end

  def test_new_pipeline_form
    get "/pipelines/new"
    assert_response(:success)
  end

  def test_create_pipeline
    post "/pipelines", params: { pipeline: { name: "Sales" } }
    follow_redirect!
    assert_select("td", "Sales")
  end

  def test_show_pipeline
    pipeline_id = create_pipeline("Sales")

    get "/pipelines/#{pipeline_id}"
    assert_response(:success)
    assert_select("h1", "Sales")
  end

  def test_add_stage
    pipeline_id = create_pipeline("Sales")

    post "/pipelines/#{pipeline_id}/add_stage", params: { stage: { name: "Qualification" } }
    follow_redirect!
    assert_select("h3", "Qualification")
  end

  def test_remove_stage
    pipeline_id = create_pipeline("Sales")
    add_stage(pipeline_id, "Qualification")

    delete "/pipelines/#{pipeline_id}/remove_stage", params: { stage: { name: "Qualification" } }
    follow_redirect!
    assert_select("h3", { text: "Qualification", count: 0 })
  end

  def test_move_deal_to_stage
    pipeline_id = create_pipeline("Sales")
    add_stage(pipeline_id, "Qualification")
    deal_id = create_deal(pipeline_id, "Big Deal")

    patch "/pipelines/#{pipeline_id}/move_deal", params: { deal_id: deal_id, stage: "Qualification" }
    follow_redirect!
    assert_response(:success)
  end

  def test_show_pipeline_with_deals_grouped_by_stage
    pipeline_id = create_pipeline("Sales")
    add_stage(pipeline_id, "Lead")
    add_stage(pipeline_id, "Negotiation")
    create_deal(pipeline_id, "Deal A")
    deal_b_id = create_deal(pipeline_id, "Deal B")
    command_bus.call(Crm::MoveDealToStage.new(deal_id: deal_b_id, stage: "Lead"))

    get "/pipelines/#{pipeline_id}"
    assert_response(:success)
    assert_select("h3", "Lead")
    assert_select("h3", "Negotiation")
    assert_select(".deal-card", "Deal A")
    assert_select(".deal-card", "Deal B")
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

  def create_deal(pipeline_id, name)
    deal_id = SecureRandom.uuid
    command_bus.call(Crm::CreateDeal.new(deal_id: deal_id, pipeline_id: pipeline_id, name: name))
    deal_id
  end
end
