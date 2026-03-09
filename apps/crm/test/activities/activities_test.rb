require "test_helper"

module Activities
  class ActivitiesTest < InMemoryRESTestCase
    cover "Activities*"

    def test_contact_registered
      register_contact(contact_id, "Alice")
      register_contact(other_contact_id, "Bob")

      contacts = Activities.all.select { |a| a.action.include?("Contact registered") }
      assert_equal(2, contacts.count)
      assert_equal("contact", contacts.last.entity_type)
      assert_equal(contact_id, contacts.last.entity_uid)
      assert_equal("Contact registered: Alice", contacts.last.action)
    end

    def test_contact_email_set
      register_contact(contact_id, "Alice")
      set_contact_email(contact_id, "alice@example.com")
      register_contact(other_contact_id, "Bob")
      set_contact_email(other_contact_id, "bob@example.com")

      emails = Activities.all.select { |a| a.action.include?("Contact email set") }
      assert_equal(2, emails.count)
      assert_equal(contact_id, emails.last.entity_uid)
      assert_equal("Contact email set: alice@example.com", emails.last.action)
    end

    def test_contact_phone_set
      register_contact(contact_id, "Alice")
      set_contact_phone(contact_id, "+1234567890")
      register_contact(other_contact_id, "Bob")
      set_contact_phone(other_contact_id, "+0987654321")

      phones = Activities.all.select { |a| a.action.include?("Contact phone set") }
      assert_equal(2, phones.count)
      assert_equal(contact_id, phones.last.entity_uid)
      assert_equal("Contact phone set: +1234567890", phones.last.action)
    end

    def test_contact_linkedin_url_set
      register_contact(contact_id, "Alice")
      set_contact_linkedin(contact_id, "https://linkedin.com/in/alice")
      register_contact(other_contact_id, "Bob")
      set_contact_linkedin(other_contact_id, "https://linkedin.com/in/bob")

      linkedins = Activities.all.select { |a| a.action.include?("Contact LinkedIn URL set") }
      assert_equal(2, linkedins.count)
      assert_equal(contact_id, linkedins.last.entity_uid)
      assert_equal("Contact LinkedIn URL set: https://linkedin.com/in/alice", linkedins.last.action)
    end

    def test_company_registered
      register_company(company_id, "Arkency")
      register_company(other_company_id, "Acme")

      companies = Activities.all.select { |a| a.action.include?("Company registered") }
      assert_equal(2, companies.count)
      assert_equal(company_id, companies.last.entity_uid)
      assert_equal("Company registered: Arkency", companies.last.action)
      assert_equal("company", companies.last.entity_type)
    end

    def test_company_linkedin_url_set
      register_company(company_id, "Arkency")
      set_company_linkedin(company_id, "https://linkedin.com/company/arkency")
      register_company(other_company_id, "Acme")
      set_company_linkedin(other_company_id, "https://linkedin.com/company/acme")

      linkedins = Activities.all.select { |a| a.action.include?("Company LinkedIn URL set") }
      assert_equal(2, linkedins.count)
      assert_equal(company_id, linkedins.last.entity_uid)
      assert_equal("Company LinkedIn URL set: https://linkedin.com/company/arkency", linkedins.last.action)
    end

    def test_pipeline_created
      create_pipeline(pipeline_id, "Sales")
      create_pipeline(other_pipeline_id, "Support")

      pipelines = Activities.all.select { |a| a.action.include?("Pipeline created") }
      assert_equal(2, pipelines.count)
      assert_equal(pipeline_id, pipelines.last.entity_uid)
      assert_equal("Pipeline created: Sales", pipelines.last.action)
      assert_equal("pipeline", pipelines.last.entity_type)
    end

    def test_stage_added_to_pipeline
      create_pipeline(pipeline_id, "Sales")
      add_stage(pipeline_id, "Negotiation")
      create_pipeline(other_pipeline_id, "Support")
      add_stage(other_pipeline_id, "Triage")

      stages = Activities.all.select { |a| a.action.include?("Stage added to pipeline") }
      assert_equal(2, stages.count)
      assert_equal(pipeline_id, stages.last.entity_uid)
      assert_equal("Stage added to pipeline: Negotiation", stages.last.action)
      assert_equal("pipeline", stages.last.entity_type)
    end

    def test_stage_removed_from_pipeline
      create_pipeline(pipeline_id, "Sales")
      add_stage(pipeline_id, "Negotiation")
      remove_stage(pipeline_id, "Negotiation")
      create_pipeline(other_pipeline_id, "Support")
      add_stage(other_pipeline_id, "Triage")
      remove_stage(other_pipeline_id, "Triage")

      stages = Activities.all.select { |a| a.action.include?("Stage removed from pipeline") }
      assert_equal(2, stages.count)
      assert_equal(pipeline_id, stages.last.entity_uid)
      assert_equal("Stage removed from pipeline: Negotiation", stages.last.action)
    end

    def test_deal_created
      create_deal(deal_id, pipeline_id, "Big Deal")
      create_deal(other_deal_id, pipeline_id, "Small Deal")

      deals = Activities.all.select { |a| a.action.include?("Deal created") }
      assert_equal(2, deals.count)
      assert_equal(deal_id, deals.last.entity_uid)
      assert_equal("Deal created: Big Deal", deals.last.action)
      assert_equal("deal", deals.last.entity_type)
    end

    def test_deal_value_set
      create_deal(deal_id, pipeline_id, "Big Deal")
      set_deal_value(deal_id, 10_000)
      create_deal(other_deal_id, pipeline_id, "Small Deal")
      set_deal_value(other_deal_id, 5_000)

      values = Activities.all.select { |a| a.action.include?("Deal value set") }
      assert_equal(2, values.count)
      assert_equal(deal_id, values.last.entity_uid)
      assert_equal("Deal value set: 10000", values.last.action)
    end

    def test_deal_expected_close_date_set
      create_deal(deal_id, pipeline_id, "Big Deal")
      set_deal_close_date(deal_id, "2026-03-01")
      create_deal(other_deal_id, pipeline_id, "Small Deal")
      set_deal_close_date(other_deal_id, "2026-06-01")

      dates = Activities.all.select { |a| a.action.include?("Deal expected close date set") }
      assert_equal(2, dates.count)
      assert_equal(deal_id, dates.last.entity_uid)
      assert_equal("Deal expected close date set: 2026-03-01", dates.last.action)
    end

    def test_deal_moved_to_stage
      create_deal(deal_id, pipeline_id, "Big Deal")
      move_deal_to_stage(deal_id, "Negotiation")
      create_deal(other_deal_id, pipeline_id, "Small Deal")
      move_deal_to_stage(other_deal_id, "Closed Won")

      moves = Activities.all.select { |a| a.action.include?("Deal moved to stage") }
      assert_equal(2, moves.count)
      assert_equal(deal_id, moves.last.entity_uid)
      assert_equal("Deal moved to stage: Negotiation", moves.last.action)
    end

    def test_contact_assigned_to_company
      register_company(company_id, "Arkency")
      register_company(other_company_id, "Acme")
      register_contact(contact_id, "Alice")
      assign_contact_to_company(contact_id, company_id)
      register_contact(other_contact_id, "Bob")
      assign_contact_to_company(other_contact_id, other_company_id)

      activities = Activities.all.select { |a| a.action.include?("assigned to company") }
      assert_equal(2, activities.count)
      assert_equal(contact_id, activities.last.entity_uid)
      assert_equal("Alice assigned to company: Arkency", activities.last.action)
      assert_equal("contact", activities.last.entity_type)
    end

    def test_company_assigned_to_deal
      register_company(company_id, "Arkency")
      register_company(other_company_id, "Acme")
      create_deal(deal_id, pipeline_id, "Big Deal")
      assign_company_to_deal(deal_id, company_id)
      create_deal(other_deal_id, pipeline_id, "Small Deal")
      assign_company_to_deal(other_deal_id, other_company_id)

      activities = Activities.all.select { |a| a.action.include?("assigned to deal") && a.action.include?("Arkency") }
      assert_equal(1, activities.count)
      assert_equal(deal_id, activities.first.entity_uid)
      assert_equal("Arkency assigned to deal: Big Deal", activities.first.action)
      assert_equal("deal", activities.first.entity_type)
    end

    def test_contact_assigned_to_deal
      register_contact(contact_id, "Alice")
      register_contact(other_contact_id, "Bob")
      create_deal(deal_id, pipeline_id, "Big Deal")
      assign_contact_to_deal(deal_id, contact_id)
      create_deal(other_deal_id, pipeline_id, "Small Deal")
      assign_contact_to_deal(other_deal_id, other_contact_id)

      activities = Activities.all.select { |a| a.action.include?("assigned to deal") && a.action.include?("Alice") }
      assert_equal(1, activities.count)
      assert_equal(deal_id, activities.first.entity_uid)
      assert_equal("Alice assigned to deal: Big Deal", activities.first.action)
      assert_equal("deal", activities.first.entity_type)
    end

    def test_recent_returns_limited_results
      register_contact(contact_id, "Alice")
      register_company(company_id, "Arkency")
      create_pipeline(pipeline_id, "Sales")

      assert_equal(3, Activities.all.count)
      assert_equal(2, Activities.recent(2).count)
    end

    def test_recent_returns_newest_first
      register_contact(contact_id, "Alice")
      register_company(company_id, "Arkency")

      recent = Activities.recent(2)
      assert_equal("Company registered: Arkency", recent.first.action)
      assert_equal("Contact registered: Alice", recent.last.action)
    end

    def test_all_returns_all_in_reverse_order
      register_contact(contact_id, "Alice")
      register_company(company_id, "Arkency")
      create_pipeline(pipeline_id, "Sales")

      all = Activities.all
      assert_equal(3, all.count)
      assert_equal("Pipeline created: Sales", all.first.action)
      assert_equal("Contact registered: Alice", all.last.action)
    end

    private

    def contact_id
      @contact_id ||= SecureRandom.uuid
    end

    def other_contact_id
      @other_contact_id ||= SecureRandom.uuid
    end

    def company_id
      @company_id ||= SecureRandom.uuid
    end

    def other_company_id
      @other_company_id ||= SecureRandom.uuid
    end

    def pipeline_id
      @pipeline_id ||= SecureRandom.uuid
    end

    def other_pipeline_id
      @other_pipeline_id ||= SecureRandom.uuid
    end

    def deal_id
      @deal_id ||= SecureRandom.uuid
    end

    def other_deal_id
      @other_deal_id ||= SecureRandom.uuid
    end

    def register_contact(uid, name)
      event_store.publish(Crm::ContactRegistered.new(data: { contact_id: uid, name: name }))
    end

    def set_contact_email(uid, email)
      event_store.publish(Crm::ContactEmailSet.new(data: { contact_id: uid, email: email }))
    end

    def set_contact_phone(uid, phone)
      event_store.publish(Crm::ContactPhoneSet.new(data: { contact_id: uid, phone: phone }))
    end

    def set_contact_linkedin(uid, url)
      event_store.publish(Crm::ContactLinkedinUrlSet.new(data: { contact_id: uid, linkedin_url: url }))
    end

    def register_company(uid, name)
      event_store.publish(Crm::CompanyRegistered.new(data: { company_id: uid, name: name }))
    end

    def set_company_linkedin(uid, url)
      event_store.publish(Crm::CompanyLinkedinUrlSet.new(data: { company_id: uid, linkedin_url: url }))
    end

    def create_pipeline(uid, name)
      event_store.publish(Crm::PipelineCreated.new(data: { pipeline_id: uid, name: name }))
    end

    def add_stage(uid, stage_name)
      event_store.publish(Crm::StageAddedToPipeline.new(data: { pipeline_id: uid, stage_name: stage_name }))
    end

    def remove_stage(uid, stage_name)
      event_store.publish(Crm::StageRemovedFromPipeline.new(data: { pipeline_id: uid, stage_name: stage_name }))
    end

    def create_deal(uid, pipeline_uid, name)
      event_store.publish(Crm::DealCreated.new(data: { deal_id: uid, pipeline_id: pipeline_uid, name: name }))
    end

    def set_deal_value(uid, value)
      event_store.publish(Crm::DealValueSet.new(data: { deal_id: uid, value: value }))
    end

    def set_deal_close_date(uid, date)
      event_store.publish(Crm::DealExpectedCloseDateSet.new(data: { deal_id: uid, expected_close_date: date }))
    end

    def move_deal_to_stage(uid, stage)
      event_store.publish(Crm::DealMovedToStage.new(data: { deal_id: uid, stage: stage }))
    end

    def assign_contact_to_company(contact_uid, company_uid)
      event_store.publish(Crm::ContactAssignedToCompany.new(data: { position_id: SecureRandom.uuid, contact_id: contact_uid, company_id: company_uid }))
    end

    def assign_company_to_deal(deal_uid, company_uid)
      event_store.publish(Crm::CompanyAssignedToDeal.new(data: { deal_id: deal_uid, company_id: company_uid }))
    end

    def assign_contact_to_deal(deal_uid, contact_uid)
      event_store.publish(Crm::ContactAssignedToDeal.new(data: { deal_id: deal_uid, contact_id: contact_uid }))
    end
  end
end
