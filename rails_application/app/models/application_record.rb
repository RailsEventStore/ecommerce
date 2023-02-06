class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.with_advisory_lock(*args)
    transaction(requires_new: true) do
      ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(#{Zlib.crc32(args.join)})")
      yield
    end
  end
end
