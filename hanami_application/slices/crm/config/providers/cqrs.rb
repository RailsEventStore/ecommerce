# frozen_string_literal: true

Crm::Container.register_provider :cqrs do |container|
  prepare do
    cqrs = container['application.cqrs']
    require_relative '../../../../../ecommerce/crm/lib/crm'
    Crm::Configuration.new.call(cqrs)
  end

  start do
    cqrs = container['application.cqrs']
    repo = container['repositories.customers']

    cqrs.subscribe(
      -> (event) { repo.create(id: event.data.fetch(:customer_id), name: event.data.fetch(:name)) },
      [Crm::CustomerRegistered]
    )

    cqrs.subscribe(
      -> (event) { repo.find(event.data.fetch(:customer_id)).update(vip: true) },
      [Crm::CustomerPromotedToVip]
    )
  end
end
