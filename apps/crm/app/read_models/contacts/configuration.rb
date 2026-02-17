module Contacts
  class Contact < ApplicationRecord
    self.table_name = "contacts"
  end
  private_constant :Contact

  def self.all
    Contact.order(id: :asc)
  end

  def self.find_by_uid(uid)
    Contact.find_by!(uid: uid)
  end

  class RegisterContact
    def call(event)
      Contact.create!(
        uid: event.data.fetch(:contact_id),
        name: event.data.fetch(:name)
      )
    end
  end

  class SetEmail
    def call(event)
      Contact.find_by!(uid: event.data.fetch(:contact_id)).update!(email: event.data.fetch(:email))
    end
  end

  class SetPhone
    def call(event)
      Contact.find_by!(uid: event.data.fetch(:contact_id)).update!(phone: event.data.fetch(:phone))
    end
  end

  class SetLinkedinUrl
    def call(event)
      Contact.find_by!(uid: event.data.fetch(:contact_id)).update!(linkedin_url: event.data.fetch(:linkedin_url))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RegisterContact.new, to: [Crm::ContactRegistered])
      event_store.subscribe(SetEmail.new, to: [Crm::ContactEmailSet])
      event_store.subscribe(SetPhone.new, to: [Crm::ContactPhoneSet])
      event_store.subscribe(SetLinkedinUrl.new, to: [Crm::ContactLinkedinUrlSet])
    end
  end
end
