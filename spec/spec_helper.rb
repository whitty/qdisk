$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'qdisk'
# Load support files
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]  # default, enables both `should` and `expect`
  end
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]  # default, enables both `should` and `expect`
  end
end
