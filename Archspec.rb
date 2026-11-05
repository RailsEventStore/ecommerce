def dependency_rules
  domains.each do |domain|
    domain.can_only_use :infra
  end

  boundaries.each do |boundary|
    boundary.can_only_use :infra, :composition, :apps, *rails_domain_names
  end

  apps.can_only_use :infra, :composition, *domain_names, *boundary_names
  composition.can_only_use :infra, *domain_names
  infra.can_only_use

  no_cycles among: [:infra, :composition, *domain_names]
end

def define_components
  infra
  composition
  domains
  boundaries
  apps
end

def domains
  domain_paths.map do |name, path|
    component name, in: path
  end
end

def boundaries
  boundary_paths.map do |name, paths|
    component name, in: paths
  end
end

def apps
  component :apps, in: "apps/*/{app,config,lib}/**/*.rb", except: boundary_paths.values.flatten
end

def composition
  component :composition, in: "domains/configuration.rb"
end

def infra
  component :infra, in: "infra/lib/**/*.rb"
end

def domain_names
  domain_paths.keys
end

def boundary_names
  boundary_paths.keys
end

def rails_domain_names
  %w[
    authentication communication crm fulfillment inventory invoicing
    payments pricing product_catalog shipping stores taxes todo
  ].map do |name|
    :"domain_#{name}"
  end
end

def domain_paths
  each_directory("domains/*").to_h do |name, path|
    [:"domain_#{name}", "#{path}/lib/**/*.rb"]
  end
end

def boundary_paths
  read_model_paths.merge(process_paths)
end

def read_model_paths
  each_directory("apps/rails_application/app/read_models/*").to_h do |name, path|
    [:"read_model_#{name}", ["#{path}/**/*.rb"]]
  end
end

def process_paths
  paths = %w[
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
  paths.fetch(:process_invoice_generation) << "apps/rails_application/app/processes/processes/invoices/**/*.rb"
  paths
end

source "apps/*/{app,config,lib}/**/*.rb",
       "domains/*/lib/**/*.rb",
       "domains/configuration.rb",
       "infra/lib/**/*.rb"

todo "archspec_todo.yml"

define_components
dependency_rules
