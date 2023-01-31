require 'fileutils'

class BuildEventsCatalog
  PATH = "./"
  EVENTS_CATALOG_DIRECTORY_NAME = "events_catalog"

  def call
    recreate_domains_catalog
    read_domains.each do |domain|
      domain_directory = create_domain_directory(domain)
    end
  end

  def read_domains
    Dir.entries(PATH).select {|entry| File.directory?(entry) and !(entry =='.' || entry == '..') }
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
    domain_directory = "#{domains_catalog}/#{domain.capitalize}"
    FileUtils.mkdir(domain_directory)
    puts " * domain directory created: #{domain_directory}"
    domain_directory
  end
end

BuildEventsCatalog.new.call
