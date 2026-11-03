require "yaml"

source "apps/*/{app,config,lib}/**/*.rb", "domains/*/lib/**/*.rb", "domains/configuration.rb", "infra/lib/**/*.rb"
todo "archspec_todo.yml"

architecture = YAML.safe_load_file(File.join(__dir__, "apps/rails_application/config/architecture.yml"))

infra = component :infra, in: "infra/lib/**/*.rb"
composition = component :composition, in: "domains/configuration.rb"

domains = each_directory("domains/*").map do |name, path|
  component :"domain_#{name}", in: "#{path}/lib/**/*.rb"
end

boundary_paths = { "read_models" => "read_model", "processes" => "process" }.flat_map do |section, type|
  architecture.fetch(section).map do |definition|
    paths = Array(definition.fetch("path"))
    name = :"#{type}_#{File.basename(paths.first, ".rb")}"
    [name, paths.map do |path|
      rooted_path = File.join("apps/rails_application", path)
      path.end_with?(".rb") ? rooted_path : "#{rooted_path}/**/*.rb"
    end]
  end
end.to_h

boundaries = boundary_paths.map do |name, paths|
  component name, in: paths
end

apps = component :apps, in: "apps/*/{app,config,lib}/**/*.rb", except: boundary_paths.values.flatten

domain_names = domains.map(&:name)
bounded_context_names = architecture.fetch("bounded_contexts").map do |definition|
  :"domain_#{File.basename(File.dirname(definition.fetch("path")))}"
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
