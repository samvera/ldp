require 'lamprey'

RSpec.configure do |config|
  config.before(:each, lamprey_server: true) do
    @runner = Ldp::Runner.new(RDF::Lamprey)
    @runner.boot
    @server = @runner.server
    @lamprey = @server.app
    @repository = @lamprey.settings.repository
    @debug = ENV.fetch('DEBUG', false)

    @connection = Faraday.new(url: @server.url) do |faraday|
      faraday.response(:logger) if @debug
      faraday.adapter(Faraday.default_adapter)
    end

    @client = Ldp::Client.new(@connection, repository: @repository)
  end

  config.after(:each, lamprey_server: true) do
    @lamprey.helpers.class.quit!
  end
end
