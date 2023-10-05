# frozen_string_literal: true

group :server do
  guard "puma", port: ENV.fetch("HANAMI_PORT", 2300) do
    watch(%r{config/*})
    watch(%r{lib/*})
    watch(%r{app/*})
    watch(%r{slices/*})
  end
end
