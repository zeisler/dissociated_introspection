$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dissociated_introspection'
if ENV['CODECLIMATE_REPO_TOKEN']
  require "simplecov"
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

RSpec.configure do |c|
  c.disable_monkey_patching!
  c.seed = "random"

  c.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end
end
