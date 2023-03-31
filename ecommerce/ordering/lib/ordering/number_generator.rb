module Ordering
  class NumberGenerator
    def call
      Time.now.utc.strftime("%Y/%m/#{random_number}")
    end

    private

    def random_number
      SecureRandom.random_number(100)
    end
  end
end
