require 'ldp/version'
require 'linkeddata'

module Ldp
  RDF::Graph.send(:include, RDF::Isomorphic)

  require 'ldp/client'
  require 'ldp/uri'

  extend Uri

  autoload :Response, 'ldp/response'
  autoload :Resource, 'ldp/resource'
  autoload :Container, 'ldp/container'

  autoload :Orm, 'ldp/orm'
end