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

['Fearless Refactoring: Rails controllers',
 'Rails meets React.js',
 'Developers Oriented Project Management',
 'Blogging for busy programmers']
.each do |name|
  Product.create(name: name)
end
