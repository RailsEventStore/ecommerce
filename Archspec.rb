source "apps/*/{app,config,lib}/**/*.rb", "domains/*/lib/**/*.rb", "domains/configuration.rb", "infra/lib/**/*.rb"

infra = component :infra, in: "infra/lib/**/*.rb"
composition = component :composition, in: "domains/configuration.rb"

domains = each_directory("domains/*").map do |name, path|
  component_name = :"domain_#{name}"
  [component_name, component(component_name, in: "#{path}/lib/**/*.rb")]
end

domain_names = domains.map(&:first)
apps = component :apps, in: "apps/*/{app,config,lib}/**/*.rb"

apps.can_only_use :infra, :composition, *domain_names

domains.each do |_name, domain|
  domain.can_only_use :infra
end

composition.can_only_use :infra, *domain_names
infra.can_only_use

no_cycles
