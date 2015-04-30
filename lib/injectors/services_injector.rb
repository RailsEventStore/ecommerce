module Injectors
  class ServicesInjector
    def number_generator
      Domain::Services::NumberGenerator.new
    end
  end
end
