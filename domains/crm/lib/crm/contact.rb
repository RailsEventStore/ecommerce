module Crm
  class Contact
    include AggregateRoot

    AlreadyRegistered = Class.new(StandardError)
    NotFound = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def register(name)
      raise AlreadyRegistered if @registered
      apply ContactRegistered.new(data: { contact_id: @id, name: name })
    end

    def set_email(email)
      raise NotFound unless @registered
      apply ContactEmailSet.new(data: { contact_id: @id, email: email })
    end

    def set_phone(phone)
      raise NotFound unless @registered
      apply ContactPhoneSet.new(data: { contact_id: @id, phone: phone })
    end

    def set_linkedin_url(linkedin_url)
      raise NotFound unless @registered
      apply ContactLinkedinUrlSet.new(data: { contact_id: @id, linkedin_url: linkedin_url })
    end

    on ContactRegistered do |event|
      @registered = true
    end

    on ContactEmailSet do |event|
    end

    on ContactPhoneSet do |event|
    end

    on ContactLinkedinUrlSet do |event|
    end
  end
end
