class Result
  attr_reader :status, :args

  def initialize(status, *args)
    @status = status
    @args = args
  end

  def path(name, &block)
    return unless @status == name.to_sym

    block.call(*@args)
  end
end
