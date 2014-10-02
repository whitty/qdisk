$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'qdisk'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]  # default, enables both `should` and `expect`
  end
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]  # default, enables both `should` and `expect`
  end
end

def command_output(name)
  base = Pathname('spec/sample')
  File.open(base + name, "r")
end

def set_process_output(name)
  IO.should_receive(:popen).and_yield(command_output(name))
end
