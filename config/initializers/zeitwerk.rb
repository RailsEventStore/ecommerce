Rails.autoloaders.each do |autoloader|
  autoloader.ignore(Rails.root.join('pricing'))
  autoloader.ignore(Rails.root.join('product_catalog'))
  autoloader.ignore(Rails.root.join('lib'))
end

require Rails.root.join("lib/configuration")

require Rails.root.join("pricing/lib/pricing")
require Rails.root.join("product_catalog/lib/product_catalog")