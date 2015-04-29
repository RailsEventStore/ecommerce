module Domain
  module Services
    class NumberGenerator
      def call
        Time.current.strftime("%Y/%m/#{SecureRandom.random_number(100)}")
      end
    end
  end
end
