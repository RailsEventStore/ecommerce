Rails.autoloaders.each do |autoloader|
  autoloader.collapse(Rails.root.join("ordering/lib/ordering/cmd_handlers"))
  autoloader.collapse(Rails.root.join("ordering/lib/ordering/events"))
  autoloader.collapse(Rails.root.join("ordering/lib/ordering/commands"))
  autoloader.ignore(Rails.root.join('pricing'))
  autoloader.ignore(Rails.root.join('product_catalog'))
end

require Rails.root.join("pricing/lib/pricing")
require Rails.root.join("product_catalog/lib/product_catalog")