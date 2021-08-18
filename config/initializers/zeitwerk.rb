Rails.autoloaders.each do |autoloader|
  autoloader.ignore(Rails.root.join('lib'))
end

require Rails.root.join("lib/configuration")