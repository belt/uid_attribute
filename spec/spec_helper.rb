begin; require 'cover_me'; rescue LoadError; end
require 'rubygems'
require 'rspec'
#require 'rr'
#require 'spec/rr'  # not updated to rspec-2

begin; require 'database_cleaner'; rescue LoadError; end

# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
# Capybara.default_selector = :css

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :mocha
end

