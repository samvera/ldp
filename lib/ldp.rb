require 'ldp/version'
require 'linkeddata'
require 'logger'

module Ldp
  RDF::Graph.send(:include, RDF::Isomorphic)

  require 'ldp/client'
  require 'ldp/uri'

  extend Uri

  autoload :Response, 'ldp/response'
  autoload :Resource, 'ldp/resource'
  autoload :Container, 'ldp/container'

  autoload :Orm, 'ldp/orm'

  class NotFound < StandardError; end

  class << self
    def logger
      @logger ||= Logger.new(STDOUT).tap do |log|
        log.level = Logger::WARN
      end
    end

    attr_writer :logger
  end
  
end
