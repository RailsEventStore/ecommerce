# frozen_string_literal: true

max_threads_count = ENV.fetch("HANAMI_MAX_THREADS", 5)
min_threads_count = ENV.fetch("HANAMI_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

port        ENV.fetch("HANAMI_PORT", 2300)
environment ENV.fetch("HANAMI_ENV", "development")
workers     ENV.fetch("HANAMI_WEB_CONCURRENCY", 2)

on_worker_boot do
  Hanami.shutdown
end

preload_app!
