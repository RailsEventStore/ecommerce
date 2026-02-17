module Crm
  class Company
    include AggregateRoot

    AlreadyRegistered = Class.new(StandardError)
    NotFound = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def register(name)
      raise AlreadyRegistered if @registered
      apply CompanyRegistered.new(data: { company_id: @id, name: name })
    end

    def set_linkedin_url(linkedin_url)
      raise NotFound unless @registered
      apply CompanyLinkedinUrlSet.new(data: { company_id: @id, linkedin_url: linkedin_url })
    end

    on CompanyRegistered do |event|
      @registered = true
    end

    on CompanyLinkedinUrlSet do |event|
    end
  end
end
