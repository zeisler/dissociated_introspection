$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dissociated_introspection'
if ENV['CODECLIMATE_REPO_TOKEN']
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

