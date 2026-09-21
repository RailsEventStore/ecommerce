require_relative "test_helper"

module Crm
  class CommandsTest < Test
    cover "Crm*"

    PRIMARY_ID = "123e4567-e89b-42d3-a456-426614174000"
    SECONDARY_ID = "223e4567-e89b-42d3-a456-426614174000"
    TERTIARY_ID = "323e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      commands_with_attributes.each do |command, attributes|
        attributes.each do |attribute, value|
          assert_equal(value, command.public_send(attribute))
        end
      end
    end

    def test_exposes_aggregate_ids
      aggregate_commands.each do |command, aggregate_id|
        assert_equal(aggregate_id, command.aggregate_id)
      end
    end

    def test_rejects_invalid_ids
      id_constructors.each do |constructor|
        invalid_ids.each do |id|
          assert_raises(Infra::Command::Invalid) { constructor.call(id) }
        end
      end

      id = Class.new(String).new(PRIMARY_ID)
      id_constructors.each do |constructor|
        assert(constructor.call(id))
      end
    end

    def test_requires_strings
      string_constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
      end

      string = Class.new(String).new("value")
      string_constructors.each do |constructor|
        assert_equal(string, constructor.call(string))
      end
    end

    def test_requires_integer_deal_value
      assert_equal(10, SetDealValue.new(PRIMARY_ID, 10).value)
      assert_raises(Infra::Command::Invalid) { SetDealValue.new(PRIMARY_ID, "10") }
      assert_raises(Infra::Command::Invalid) { SetDealValue.new(PRIMARY_ID, 10.0) }
    end

    private

    def commands_with_attributes
      [
        [RegisterCustomer.new(PRIMARY_ID, "Customer"), { customer_id: PRIMARY_ID, name: "Customer" }],
        [RenameCustomer.new(PRIMARY_ID, "Renamed"), { customer_id: PRIMARY_ID, name: "Renamed" }],
        [PromoteCustomerToVip.new(PRIMARY_ID), { customer_id: PRIMARY_ID }],
        [AssignCustomerToOrder.new(PRIMARY_ID, SECONDARY_ID), { customer_id: PRIMARY_ID, order_id: SECONDARY_ID }],
        [RegisterContact.new(PRIMARY_ID, "Contact"), { contact_id: PRIMARY_ID, name: "Contact" }],
        [SetContactEmail.new(PRIMARY_ID, "mail@example.com"), { contact_id: PRIMARY_ID, email: "mail@example.com" }],
        [SetContactPhone.new(PRIMARY_ID, "123"), { contact_id: PRIMARY_ID, phone: "123" }],
        [SetContactLinkedinUrl.new(PRIMARY_ID, "https://example.com"), { contact_id: PRIMARY_ID, linkedin_url: "https://example.com" }],
        [AssignContactToCompany.new(PRIMARY_ID, SECONDARY_ID, TERTIARY_ID), { position_id: PRIMARY_ID, contact_id: SECONDARY_ID, company_id: TERTIARY_ID }],
        [RegisterCompany.new(PRIMARY_ID, "Company"), { company_id: PRIMARY_ID, name: "Company" }],
        [SetCompanyLinkedinUrl.new(PRIMARY_ID, "https://example.com"), { company_id: PRIMARY_ID, linkedin_url: "https://example.com" }],
        [CreatePipeline.new(PRIMARY_ID, "Pipeline"), { pipeline_id: PRIMARY_ID, name: "Pipeline" }],
        [AddStageToPipeline.new(PRIMARY_ID, "Lead"), { pipeline_id: PRIMARY_ID, stage_name: "Lead" }],
        [RemoveStageFromPipeline.new(PRIMARY_ID, "Lead"), { pipeline_id: PRIMARY_ID, stage_name: "Lead" }],
        [CreateDeal.new(PRIMARY_ID, SECONDARY_ID, "Deal"), { deal_id: PRIMARY_ID, pipeline_id: SECONDARY_ID, name: "Deal" }],
        [SetDealValue.new(PRIMARY_ID, 10), { deal_id: PRIMARY_ID, value: 10 }],
        [SetDealExpectedCloseDate.new(PRIMARY_ID, "2026-09-21"), { deal_id: PRIMARY_ID, expected_close_date: "2026-09-21" }],
        [MoveDealToStage.new(PRIMARY_ID, "Lead"), { deal_id: PRIMARY_ID, stage: "Lead" }],
        [AssignCompanyToDeal.new(PRIMARY_ID, SECONDARY_ID, TERTIARY_ID), { deal_party_id: PRIMARY_ID, deal_id: SECONDARY_ID, company_id: TERTIARY_ID }],
        [AssignContactToDeal.new(PRIMARY_ID, SECONDARY_ID, TERTIARY_ID), { deal_party_id: PRIMARY_ID, deal_id: SECONDARY_ID, contact_id: TERTIARY_ID }]
      ]
    end

    def aggregate_commands
      [
        [RegisterCustomer.new(PRIMARY_ID, "Customer"), PRIMARY_ID],
        [RenameCustomer.new(PRIMARY_ID, "Customer"), PRIMARY_ID],
        [PromoteCustomerToVip.new(PRIMARY_ID), PRIMARY_ID],
        [AssignCustomerToOrder.new(PRIMARY_ID, SECONDARY_ID), SECONDARY_ID],
        [RegisterContact.new(PRIMARY_ID, "Contact"), PRIMARY_ID],
        [SetContactEmail.new(PRIMARY_ID, "mail@example.com"), PRIMARY_ID],
        [SetContactPhone.new(PRIMARY_ID, "123"), PRIMARY_ID],
        [SetContactLinkedinUrl.new(PRIMARY_ID, "https://example.com"), PRIMARY_ID],
        [AssignContactToCompany.new(PRIMARY_ID, SECONDARY_ID, TERTIARY_ID), PRIMARY_ID],
        [RegisterCompany.new(PRIMARY_ID, "Company"), PRIMARY_ID],
        [SetCompanyLinkedinUrl.new(PRIMARY_ID, "https://example.com"), PRIMARY_ID],
        [CreatePipeline.new(PRIMARY_ID, "Pipeline"), PRIMARY_ID],
        [AddStageToPipeline.new(PRIMARY_ID, "Lead"), PRIMARY_ID],
        [RemoveStageFromPipeline.new(PRIMARY_ID, "Lead"), PRIMARY_ID],
        [CreateDeal.new(PRIMARY_ID, SECONDARY_ID, "Deal"), PRIMARY_ID],
        [SetDealValue.new(PRIMARY_ID, 10), PRIMARY_ID],
        [SetDealExpectedCloseDate.new(PRIMARY_ID, "2026-09-21"), PRIMARY_ID],
        [MoveDealToStage.new(PRIMARY_ID, "Lead"), PRIMARY_ID],
        [AssignCompanyToDeal.new(PRIMARY_ID, SECONDARY_ID, TERTIARY_ID), PRIMARY_ID],
        [AssignContactToDeal.new(PRIMARY_ID, SECONDARY_ID, TERTIARY_ID), PRIMARY_ID]
      ]
    end

    def invalid_ids
      ["not-a-uuid", Object.new, "123e4567-e89b-12d3-a456-426614174000", "123e4567-e89b-42d3-7456-426614174000"]
    end

    def id_constructors
      [
        ->(id) { RegisterCustomer.new(id, "Customer") },
        ->(id) { RenameCustomer.new(id, "Customer") },
        ->(id) { PromoteCustomerToVip.new(id) },
        ->(id) { AssignCustomerToOrder.new(id, SECONDARY_ID) },
        ->(id) { AssignCustomerToOrder.new(PRIMARY_ID, id) },
        ->(id) { RegisterContact.new(id, "Contact") },
        ->(id) { SetContactEmail.new(id, "mail@example.com") },
        ->(id) { SetContactPhone.new(id, "123") },
        ->(id) { SetContactLinkedinUrl.new(id, "https://example.com") },
        ->(id) { AssignContactToCompany.new(id, SECONDARY_ID, TERTIARY_ID) },
        ->(id) { AssignContactToCompany.new(PRIMARY_ID, id, TERTIARY_ID) },
        ->(id) { AssignContactToCompany.new(PRIMARY_ID, SECONDARY_ID, id) },
        ->(id) { RegisterCompany.new(id, "Company") },
        ->(id) { SetCompanyLinkedinUrl.new(id, "https://example.com") },
        ->(id) { CreatePipeline.new(id, "Pipeline") },
        ->(id) { AddStageToPipeline.new(id, "Lead") },
        ->(id) { RemoveStageFromPipeline.new(id, "Lead") },
        ->(id) { CreateDeal.new(id, SECONDARY_ID, "Deal") },
        ->(id) { CreateDeal.new(PRIMARY_ID, id, "Deal") },
        ->(id) { SetDealValue.new(id, 10) },
        ->(id) { SetDealExpectedCloseDate.new(id, "2026-09-21") },
        ->(id) { MoveDealToStage.new(id, "Lead") },
        ->(id) { AssignCompanyToDeal.new(id, SECONDARY_ID, TERTIARY_ID) },
        ->(id) { AssignCompanyToDeal.new(PRIMARY_ID, id, TERTIARY_ID) },
        ->(id) { AssignCompanyToDeal.new(PRIMARY_ID, SECONDARY_ID, id) },
        ->(id) { AssignContactToDeal.new(id, SECONDARY_ID, TERTIARY_ID) },
        ->(id) { AssignContactToDeal.new(PRIMARY_ID, id, TERTIARY_ID) },
        ->(id) { AssignContactToDeal.new(PRIMARY_ID, SECONDARY_ID, id) }
      ]
    end

    def string_constructors
      [
        ->(value) { RegisterCustomer.new(PRIMARY_ID, value).name },
        ->(value) { RenameCustomer.new(PRIMARY_ID, value).name },
        ->(value) { RegisterContact.new(PRIMARY_ID, value).name },
        ->(value) { SetContactEmail.new(PRIMARY_ID, value).email },
        ->(value) { SetContactPhone.new(PRIMARY_ID, value).phone },
        ->(value) { SetContactLinkedinUrl.new(PRIMARY_ID, value).linkedin_url },
        ->(value) { RegisterCompany.new(PRIMARY_ID, value).name },
        ->(value) { SetCompanyLinkedinUrl.new(PRIMARY_ID, value).linkedin_url },
        ->(value) { CreatePipeline.new(PRIMARY_ID, value).name },
        ->(value) { AddStageToPipeline.new(PRIMARY_ID, value).stage_name },
        ->(value) { RemoveStageFromPipeline.new(PRIMARY_ID, value).stage_name },
        ->(value) { CreateDeal.new(PRIMARY_ID, SECONDARY_ID, value).name },
        ->(value) { SetDealExpectedCloseDate.new(PRIMARY_ID, value).expected_close_date },
        ->(value) { MoveDealToStage.new(PRIMARY_ID, value).stage }
      ]
    end
  end
end
