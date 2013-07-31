$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))


require 'rspec/autorun'
require 'ldp'
require 'faraday'
require "byebug" 

RSpec.configure do |config|

end