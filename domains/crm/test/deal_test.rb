require_relative "test_helper"

module Crm
  class DealTest < Test
    cover "Crm*"

    def test_create_deal
      deal_id = SecureRandom.uuid
      pipeline_id = SecureRandom.uuid
      assert_events(
        "Crm::Deal$#{deal_id}",
        DealCreated.new(data: { deal_id: deal_id, pipeline_id: pipeline_id, name: "Big Deal" })
      ) do
        create_deal(deal_id, pipeline_id, "Big Deal")
      end
    end

    def test_cannot_create_same_deal_twice
      deal_id = SecureRandom.uuid
      pipeline_id = SecureRandom.uuid
      create_deal(deal_id, pipeline_id, "Big Deal")

      assert_raises(Deal::AlreadyCreated) do
        create_deal(deal_id, pipeline_id, "Big Deal")
      end
    end

    def test_set_deal_value
      deal_id = SecureRandom.uuid
      pipeline_id = SecureRandom.uuid
      assert_events(
        "Crm::Deal$#{deal_id}",
        DealCreated.new(data: { deal_id: deal_id, pipeline_id: pipeline_id, name: "Big Deal" }),
        DealValueSet.new(data: { deal_id: deal_id, value: 10000 })
      ) do
        create_deal(deal_id, pipeline_id, "Big Deal")
        set_deal_value(deal_id, 10000)
      end
    end

    def test_cannot_set_value_for_nonexistent_deal
      deal_id = SecureRandom.uuid

      assert_raises(Deal::NotFound) do
        set_deal_value(deal_id, 10000)
      end
    end

    def test_set_deal_expected_close_date
      deal_id = SecureRandom.uuid
      pipeline_id = SecureRandom.uuid
      assert_events(
        "Crm::Deal$#{deal_id}",
        DealCreated.new(data: { deal_id: deal_id, pipeline_id: pipeline_id, name: "Big Deal" }),
        DealExpectedCloseDateSet.new(data: { deal_id: deal_id, expected_close_date: "2026-03-01" })
      ) do
        create_deal(deal_id, pipeline_id, "Big Deal")
        set_deal_expected_close_date(deal_id, "2026-03-01")
      end
    end

    def test_cannot_set_expected_close_date_for_nonexistent_deal
      deal_id = SecureRandom.uuid

      assert_raises(Deal::NotFound) do
        set_deal_expected_close_date(deal_id, "2026-03-01")
      end
    end

    def test_move_deal_to_stage
      deal_id = SecureRandom.uuid
      pipeline_id = SecureRandom.uuid
      assert_events(
        "Crm::Deal$#{deal_id}",
        DealCreated.new(data: { deal_id: deal_id, pipeline_id: pipeline_id, name: "Big Deal" }),
        DealMovedToStage.new(data: { deal_id: deal_id, stage: "Negotiation" })
      ) do
        create_deal(deal_id, pipeline_id, "Big Deal")
        move_deal_to_stage(deal_id, "Negotiation")
      end
    end

    def test_cannot_move_nonexistent_deal_to_stage
      deal_id = SecureRandom.uuid

      assert_raises(Deal::NotFound) do
        move_deal_to_stage(deal_id, "Negotiation")
      end
    end

    private

    def create_deal(deal_id, pipeline_id, name)
      run_command(CreateDeal.new(deal_id: deal_id, pipeline_id: pipeline_id, name: name))
    end

    def set_deal_value(deal_id, value)
      run_command(SetDealValue.new(deal_id: deal_id, value: value))
    end

    def set_deal_expected_close_date(deal_id, expected_close_date)
      run_command(SetDealExpectedCloseDate.new(deal_id: deal_id, expected_close_date: expected_close_date))
    end

    def move_deal_to_stage(deal_id, stage)
      run_command(MoveDealToStage.new(deal_id: deal_id, stage: stage))
    end
  end
end
