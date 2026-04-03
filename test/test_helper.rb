ENV["RAILS_ENV"] ||= "test"
require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
end

require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    parallelize(workers: 1)

    setup do
      Rails.cache.clear
    end
  end
end
