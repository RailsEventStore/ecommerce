require "yaml"

source "apps/*/{app,config,lib}/**/*.rb", "domains/*/lib/**/*.rb", "domains/configuration.rb", "infra/lib/**/*.rb"
todo "archspec_todo.yml"

architecture = YAML.safe_load_file(File.join(__dir__, "apps/rails_application/config/architecture.yml"))

infra = component :infra, in: "infra/lib/**/*.rb"
composition = component :composition, in: "domains/configuration.rb"

domains = each_directory("domains/*").map do |name, path|
  component_name = :"domain_#{name}"
  [component_name, component(component_name, in: "#{path}/lib/**/*.rb")]
end

apps = component :apps, in: "apps/*/{app,config,lib}/**/*.rb"

read_models = architecture.fetch("read_models").map do |definition|
  path = definition.fetch("path")
  component_name = :"read_model_#{File.basename(path)}"
  [component_name, component(component_name, in: "apps/rails_application/#{path}/**/*.rb")]
end

processes = architecture.fetch("processes").map do |definition|
  configured_paths = Array(definition.fetch("path"))
  component_name = :"process_#{File.basename(configured_paths.first, ".rb")}"
  paths = configured_paths.map do |path|
    rooted_path = File.join("apps/rails_application", path)
    path.end_with?(".rb") ? rooted_path : "#{rooted_path}/**/*.rb"
  end
  [component_name, component(component_name, in: paths)]
end

domain_names = domains.map(&:first)
bounded_context_names = architecture.fetch("bounded_contexts").map do |definition|
  :"domain_#{File.basename(File.dirname(definition.fetch("path")))}"
end
boundary_names = (read_models + processes).map(&:first)

domains.each do |_name, domain|
  domain.can_only_use :infra
end

(read_models + processes).each do |_name, boundary|
  boundary.can_only_use :infra, :composition, :apps, *bounded_context_names
end

apps.can_only_use :infra, :composition, *domain_names, *boundary_names
composition.can_only_use :infra, *domain_names
infra.can_only_use

no_cycles among: [:infra, :composition, *domain_names]
