require 'fileutils'

class BuildEventsCatalog
  PATH = "./"
  SOURCE_PATH = "./ecommerce/"
  EVENTS_CATALOG_DIRECTORY_NAME = "events_catalog"

  def call
    recreate_domains_catalog
    read_domains.each do |domain|
      domain.capitalize!
      domain_directory = create_domain_directory(domain)
      create_domain_index(domain, domain_directory)
    end
  end

  def read_domains
    Dir.entries(SOURCE_PATH).select {|entry| File.directory?("#{SOURCE_PATH}#{entry}") and !(entry =='.' || entry == '..' || entry == 'processes') }
  end

  def recreate_domains_catalog
    remove_domains_catalog
    create_domains_catalog
  end

  def create_domains_catalog
    FileUtils.mkdir(domains_catalog)
  end

  def remove_domains_catalog
    File.exist?(domains_catalog) && File.directory?(domains_catalog)
    FileUtils.rm_rf(domains_catalog)
  end

  def root_catalog
    "#{PATH}#{EVENTS_CATALOG_DIRECTORY_NAME}"
  end

  def domains_catalog
    "#{root_catalog}/domains"
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
end

class DomainTemplate
  def render(name)
    <<~EOS
      ---
      name: #{name}
      summary: |
        Domain for everything shopping
      owners:
          - dboyne
          - mSmith
      ---

      <Admonition>Domain for everything to do with Shopping at our business. Before adding any events or services to this domain make sure you contact the domain owners and verify it's the correct place.</Admonition>

      ### Details

      This domain encapsulates everything in our business that has to do with shopping and users. This might be new items added to our online shop or online cart management.

      <NodeGraph title="Domain Graph" />
    EOS
  end
end

BuildEventsCatalog.new.call
