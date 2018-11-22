class Command
  ValidationError = Class.new(StandardError)

  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Conversion

  def initialize(attributes = {})
    super
  end

  def validate!
    raise ValidationError, errors unless valid?
  end
end
