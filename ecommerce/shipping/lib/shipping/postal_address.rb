module Shipping
  class PostalAddress
    attr_reader :line_1, :line_2, :line_3, :line_4

    def initialize(line_1:, line_2:, line_3:, line_4:)
      @line_1 = line_1
      @line_2 = line_2
      @line_3 = line_3
      @line_4 = line_4
    end
  end
end