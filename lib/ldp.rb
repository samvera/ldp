require 'ldp/version'
require 'rdf/turtle'
require 'json/ld'
require 'rdf/isomorphic'
require 'rdf/vocab/ldp'
require 'logger'
require 'singleton'
require 'deprecation'

module Ldp
  RDF::Graph.send(:include, RDF::Isomorphic)

  require 'ldp/error'
  require 'ldp/client'
  require 'ldp/uri'

  extend Uri

  autoload :Response, 'ldp/response'
  autoload :Resource, 'ldp/resource'
  autoload :Container, 'ldp/container'

  autoload :Orm, 'ldp/orm'

  # Returned when there is no result (e.g. 404)
  class NoneClass
    include Singleton
  end
  # The single global instance of NoneClass, representing the empty Option
  None = NoneClass.instance # :doc:

  class << self
    def logger
      @logger ||= Logger.new(STDOUT).tap do |log|
        log.level = Logger::WARN
      end
    end

    def instrument *args, &block
      if defined?(::ActiveSupport) && defined?(::ActiveSupport::Notifications)
        ActiveSupport::Notifications.instrument *args, &block
      else
        yield
      end
    end

    attr_writer :logger
  end
end
