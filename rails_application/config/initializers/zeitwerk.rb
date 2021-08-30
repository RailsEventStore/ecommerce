Rails.autoloaders.each do |autoloader|
  autoloader.ignore(Rails.root.join('app/admin'))
end