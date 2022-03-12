# frozen_string_literal: true

# How many worker processes puma should run
#
# Use WEB_CONCURRENCY=0 to disable puma's clustered mode
workers Integer(ENV["WEB_CONCURRENCY"] || 2)

# How many threads should exist in each worker's pool
#
# Setting WEB_MAX_THREADS without setting WEB_MIN_THREADS
# sets both min and max to the same value
min_threads_count = Integer(ENV["WEB_MIN_THREADS"] || ENV["WEB_MAX_THREADS"] || 5)
max_threads_count = Integer(ENV["WEB_MAX_THREADS"] || 8)
threads min_threads_count, max_threads_count

# Preload the app to boot the application before forking new workers
preload_app!

# Use the default rackup (config.ru) command
rackup DefaultRackup

# Specify the port that Puma will listen on
port ENV.fetch("PORT") { 2300 }

# Specify the environment Puma will run in
environment ENV.fetch("HANAMI_ENV") { "development" }

# Shutdown the application before forking
before_fork do
  Hanami.shutdown
end
