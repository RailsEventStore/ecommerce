class NumberGenerator
  def initialize(clock = -> { Time.now })
    @clock = clock
  end

  def call
    time_now = @clock.call
    [ year(time_now),
      month(time_now),
      next_number(sequence_key(time_now))
    ].join("/")
  end

  def reset
    time_now = @clock.call
    ActiveRecord::Base.connection.execute "ALTER SEQUENCE #{sequence_key(time_now)} restart;"
  rescue ActiveRecord::StatementInvalid => exc
    raise unless exc.message.match /#{sequence_key(time_now)}]/
  end

  private

  def year(time)
    time.year
  end

  def month(time)
    "%02d" % time.month
  end

  def sequence_key(time_now)
    "sequence_#{year(time_now)}_#{month(time_now)}"
  end

  def next_number(key)
    res = ActiveRecord::Base.connection.execute "SELECT nextval('#{key}')"
    res.first["nextval"]
  rescue ActiveRecord::StatementInvalid => exc
    ActiveRecord::Base.connection.execute "CREATE SEQUENCE #{key}"
    retry if exc.message.match /#{key}]/
  end
end
