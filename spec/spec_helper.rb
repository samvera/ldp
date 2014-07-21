$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))


require 'ldp'
require 'faraday'
require 'active_support/notifications'

RSpec.configure do |config|

end
