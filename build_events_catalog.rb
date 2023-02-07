require 'fileutils'

class BuildEventsCatalog
  PATH = "./"
  SOURCE_PATH = "./ecommerce/"
  EVENTS_CATALOG_DIRECTORY_NAME = "events_catalog"
  EVENT_TYPE = "Infra::Event"
  CONFIG_FILE = "./eventcatalog.config.js"

  def call
    configure
    clear_domains
    clear_events
    clear_services
    read_domains.each do |domain|
      domain.capitalize!
      domain_directory = create_domain_directory(domain)
      create_domain_index(domain, domain_directory)
      create_domain_events(domain)
    end
  end

  private

  def configure
    replace_config_file
  end

  def read_domains
    Dir.entries(SOURCE_PATH).select {|entry| File.directory?("#{SOURCE_PATH}#{entry}") and !(entry =='.' || entry == '..' || entry == 'processes') }
  end

  def source_domain_directory(domain)
    "#{SOURCE_PATH}#{domain.downcase}"
  end

  def clear_domains
    remove_catalog(domains_catalog)
    create_catalog(domains_catalog)
  end

  def clear_events
    remove_catalog(events_catalog)
    create_catalog(events_catalog)
  end

  def clear_services
    remove_catalog(services_catalog)
    create_catalog(services_catalog)
  end

  def create_catalog(catalog)
    FileUtils.mkdir(catalog)
  end

  def remove_catalog(catalog)
    File.exist?(catalog) && File.directory?(catalog)
    FileUtils.rm_rf(catalog)
  end

  def root_catalog
    "#{PATH}#{EVENTS_CATALOG_DIRECTORY_NAME}"
  end

  def domains_catalog
    "#{root_catalog}/domains"
  end

  def events_catalog
    "#{root_catalog}/events"
  end

  def services_catalog
    "#{root_catalog}/services"
  end

  def create_domain_directory(domain)
    domain_directory = "#{domains_catalog}/#{domain}"
    FileUtils.mkdir(domain_directory)
    puts " * domain directory created: #{domain_directory}"
    domain_directory
  end

  def create_domain_index(domain, domain_directory)
    File.open("#{domain_directory}/index.md", "w") do |f|
      f.write(DomainTemplate.new.render(domain))
    end
  end

  def create_domain_events(domain)
    domain_events_directory = "#{domains_catalog}/#{domain}/events"
    FileUtils.mkdir(domain_events_directory)
    build_events(domain)
  end

  def build_events(domain)
    scan_domain_for_events(domain).each do |event|
      domain_event_directory = "#{domains_catalog}/#{domain}/events/#{event}"
      FileUtils.mkdir(domain_event_directory)
      create_event_index(domain_event_directory, event)
    end
  end

  def create_event_index(event_directory, event)
    File.open("#{event_directory}/index.md", "w") do |f|
      f.write(EventTemplate.new.render(event))
      puts "   - event: #{event}"
    end
  end

  def scan_domain_for_events(domain)
    files =  Dir.glob("#{source_domain_directory(domain)}/**/*").reject { |f| File.directory?(f) || f =='.' || f == '..' }
    list = files.map do |file|
      IO.read(file).scan(/class (.*?) < #{EVENT_TYPE}/)
    end.flatten
      .reject {|e| e.empty?}
      .compact
  end

  def replace_config_file
    FileUtils.cp(CONFIG_FILE, root_catalog)
  end
end

class DomainTemplate
  def render(name)
    <<~EOS
      ---
      name: #{name}
      summary: |
        Summary
      owners:
        - Arkency
      ---

      <Admonition>Domain description</Admonition>

      ### Details

      -

      <NodeGraph title="Domain Graph" />
    EOS
  end
end

class EventTemplate
  def render(name)
    <<~EOS
      ---
      name: #{name}
      version: 0.0.1
      summary: |
        Summary
      owners:
        - Arkency
      ---

      #{name}

      ...
    EOS
  end
end
