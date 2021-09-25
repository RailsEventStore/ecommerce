module Ordering
  class FakeNumberGenerator
    FAKE_NUMBER = "2019/01/60".freeze
    def call
      FAKE_NUMBER
    end
  end
end
