# frozen_string_literal: true

require "pathname"
TEST_ROOT = Pathname(__dir__).realpath.freeze

ENV["HANAMI_ENV"] ||= "test"

require "fileutils"
APP_ROOT = TEST_ROOT.join("..").freeze
FileUtils.rm_f(APP_ROOT.join("db", "hanami_application_test.sqlite"))
system("bundle exec hanami db prepare", exception: true, chdir: APP_ROOT.to_s)

require "hanami/minitest"
require "hanami/boot"

require_relative "support/minitest"
TEST_ROOT.glob("support/**/*.rb").each { |f| require f }
