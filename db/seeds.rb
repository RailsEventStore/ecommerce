# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

['BigCorp Ltd', 'MegaTron Gmbh', 'Arkency'].each do |name|
  Customer.create(name: name)
end

[
  ['Fearless Refactoring: Rails controllers', 49],
  ['Rails meets React.js', 49],
  ['Developers Oriented Project Management', 39],
  ['Blogging for busy programmers', 29]
].each do |name_price_tuple|
  ProductCatalog::Product.create(name: name_price_tuple[0], price: name_price_tuple[1])
end
