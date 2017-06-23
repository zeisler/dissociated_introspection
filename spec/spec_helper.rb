$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dissociated_introspection'

RSpec.configure do |c|
  c.disable_monkey_patching!
  c.seed = "random"

  c.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end
end
