Rails.autoloaders.each do |autoloader|
  autoloader.collapse(Rails.root.join("ordering/lib/ordering/cmd_handlers"))
  autoloader.collapse(Rails.root.join("ordering/lib/ordering/events"))
  autoloader.collapse(Rails.root.join("ordering/lib/ordering/commands"))
end