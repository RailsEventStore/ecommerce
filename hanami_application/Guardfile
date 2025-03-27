# frozen_string_literal: true

guard "rack", port: ENV.fetch("PORT") { 3000 } do
  watch "Gemfile.lock"
  watch "config.ru"
  watch %r{config/.+}
  watch %r{lib/.+}
  watch %r{slices/.+}
  watch %r{system/.+}
end
