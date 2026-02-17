module Companies
  class Company < ApplicationRecord
    self.table_name = "companies"
  end
  private_constant :Company

  def self.all
    Company.order(id: :asc)
  end

  def self.find_by_uid(uid)
    Company.find_by!(uid: uid)
  end

  class RegisterCompany
    def call(event)
      Company.create!(
        uid: event.data.fetch(:company_id),
        name: event.data.fetch(:name)
      )
    end
  end

  class SetLinkedinUrl
    def call(event)
      Company.find_by!(uid: event.data.fetch(:company_id)).update!(linkedin_url: event.data.fetch(:linkedin_url))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RegisterCompany.new, to: [Crm::CompanyRegistered])
      event_store.subscribe(SetLinkedinUrl.new, to: [Crm::CompanyLinkedinUrlSet])
    end
  end
end
