module Crm
  class Deal
    include AggregateRoot

    AlreadyCreated = Class.new(StandardError)
    NotFound = Class.new(StandardError)

    def initialize(id)
      @id = id
      @company_ids = Set.new
      @contact_ids = Set.new
    end

    def create(pipeline_id, name)
      raise AlreadyCreated if @created
      apply DealCreated.new(data: { deal_id: @id, pipeline_id: pipeline_id, name: name })
    end

    def set_value(value)
      raise NotFound unless @created
      apply DealValueSet.new(data: { deal_id: @id, value: value })
    end

    def set_expected_close_date(expected_close_date)
      raise NotFound unless @created
      apply DealExpectedCloseDateSet.new(data: { deal_id: @id, expected_close_date: expected_close_date })
    end

    def move_to_stage(stage)
      raise NotFound unless @created
      apply DealMovedToStage.new(data: { deal_id: @id, stage: stage })
    end

    def assign_company(company_id)
      raise NotFound unless @created
      return if @company_ids.include?(company_id)
      apply CompanyAssignedToDeal.new(data: { deal_id: @id, company_id: company_id })
    end

    def assign_contact(contact_id)
      raise NotFound unless @created
      return if @contact_ids.include?(contact_id)
      apply ContactAssignedToDeal.new(data: { deal_id: @id, contact_id: contact_id })
    end

    on DealCreated do |event|
      @created = true
    end

    on DealValueSet do |event|
    end

    on DealExpectedCloseDateSet do |event|
    end

    on DealMovedToStage do |event|
    end

    on CompanyAssignedToDeal do |event|
      @company_ids.add(event.data.fetch(:company_id))
    end

    on ContactAssignedToDeal do |event|
      @contact_ids.add(event.data.fetch(:contact_id))
    end
  end
end
