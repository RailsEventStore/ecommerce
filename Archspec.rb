source "apps/*/{app,config,lib}/**/*.rb", "domains/*/lib/**/*.rb", "domains/configuration.rb", "infra/lib/**/*.rb"
todo "archspec_todo.yml"

infra = component :infra, in: "infra/lib/**/*.rb"
composition = component :composition, in: "domains/configuration.rb"

domains = each_directory("domains/*").map do |name, path|
  component :"domain_#{name}", in: "#{path}/lib/**/*.rb"
end

read_model_paths = each_directory("apps/rails_application/app/read_models/*").to_h do |name, path|
  [:"read_model_#{name}", ["#{path}/**/*.rb"]]
end

process_paths = %w[
  apply_time_promotion
  confirm_order_on_payment_captured
  invoice_generation
  notify_payments_about_order_value
  release_payment_on_order_expiration
  reservation_process
  shipment_process
  sync_shipment_from_pricing
  three_plus_one_free
  total_order_value
  welcome_message_process
].to_h do |name|
  [:"process_#{name}", ["apps/rails_application/app/processes/processes/#{name}.rb"]]
end
process_paths.fetch(:process_invoice_generation) << "apps/rails_application/app/processes/processes/invoices/**/*.rb"

boundary_paths = read_model_paths.merge(process_paths)

boundaries = boundary_paths.map do |name, paths|
  component name, in: paths
end

apps = component :apps, in: "apps/*/{app,config,lib}/**/*.rb", except: boundary_paths.values.flatten

domain_names = domains.map(&:name)
bounded_context_names = %w[
  authentication communication crm fulfillment inventory invoicing ordering
  payments pricing product_catalog shipping stores taxes todo
].map do |name|
  :"domain_#{name}"
end
boundary_names = boundaries.map(&:name)

domains.each do |domain|
  domain.can_only_use :infra
end

boundaries.each do |boundary|
  boundary.can_only_use :infra, :composition, :apps, *bounded_context_names
end

apps.can_only_use :infra, :composition, *domain_names, *boundary_names
composition.can_only_use :infra, *domain_names
infra.can_only_use

no_cycles among: [:infra, :composition, *domain_names]
