require "test_helper"

module Deals
  class DealsTest < InMemoryRESTestCase
    cover "Deals*"

    def test_deal_created
      create_deal(deal_id, pipeline_id, "Big Deal")

      assert_equal(1, Deals.all.count)
      deal = Deals.find_by_uid(deal_id)
      assert_equal("Big Deal", deal.name)
      assert_equal(pipeline_id, deal.pipeline_uid)
    end

    def test_multiple_deals
      create_deal(deal_id, pipeline_id, "Big Deal")
      create_deal(other_deal_id, pipeline_id, "Small Deal")

      assert_equal(2, Deals.all.count)
      assert_equal(["Big Deal", "Small Deal"], Deals.all.map(&:name))
    end

    def test_for_pipeline
      other_pipeline_id = SecureRandom.uuid
      create_deal(deal_id, pipeline_id, "Big Deal")
      create_deal(other_deal_id, other_pipeline_id, "Small Deal")

      assert_equal(["Big Deal"], Deals.for_pipeline(pipeline_id).map(&:name))
      assert_equal(["Small Deal"], Deals.for_pipeline(other_pipeline_id).map(&:name))
    end

    def test_value_set
      create_deal(deal_id, pipeline_id, "Big Deal")
      create_deal(other_deal_id, pipeline_id, "Small Deal")
      set_value(deal_id, 10_000)

      assert_equal(10_000, Deals.find_by_uid(deal_id).value)
      assert_nil(Deals.find_by_uid(other_deal_id).value)
    end

    def test_expected_close_date_set
      create_deal(deal_id, pipeline_id, "Big Deal")
      create_deal(other_deal_id, pipeline_id, "Small Deal")
      set_expected_close_date(deal_id, "2026-03-01")

      assert_equal("2026-03-01", Deals.find_by_uid(deal_id).expected_close_date)
      assert_nil(Deals.find_by_uid(other_deal_id).expected_close_date)
    end

    def test_moved_to_stage
      create_deal(deal_id, pipeline_id, "Big Deal")
      create_deal(other_deal_id, pipeline_id, "Small Deal")
      move_to_stage(deal_id, "Negotiation")

      assert_equal("Negotiation", Deals.find_by_uid(deal_id).stage)
      assert_nil(Deals.find_by_uid(other_deal_id).stage)
    end

    private

    def deal_id
      @deal_id ||= SecureRandom.uuid
    end

    def other_deal_id
      @other_deal_id ||= SecureRandom.uuid
    end

    def pipeline_id
      @pipeline_id ||= SecureRandom.uuid
    end

    def create_deal(uid, pipeline_uid, name)
      event_store.publish(Crm::DealCreated.new(data: { deal_id: uid, pipeline_id: pipeline_uid, name: name }))
    end

    def set_value(uid, value)
      event_store.publish(Crm::DealValueSet.new(data: { deal_id: uid, value: value }))
    end

    def set_expected_close_date(uid, date)
      event_store.publish(Crm::DealExpectedCloseDateSet.new(data: { deal_id: uid, expected_close_date: date }))
    end

    def move_to_stage(uid, stage)
      event_store.publish(Crm::DealMovedToStage.new(data: { deal_id: uid, stage: stage }))
    end
  end
end
