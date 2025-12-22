require "rom-factory"
require_relative "helpers"

Factory = ROM::Factory.configure { |config|
  config.rom = Test::DB::Helpers.rom
}

Dir[Pathname(__FILE__).dirname.join("../../factories/**/*.rb")].each(&method(:require))
