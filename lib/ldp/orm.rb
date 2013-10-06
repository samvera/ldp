module Ldp
  class Orm

    attr_reader :resource

    def initialize resource
      @resource = resource
    end

    def graph
      resource.graph
    end

    def value predicate
      graph.query(:subject => resource.subject_uri, :predicate => predicate).map do |stmt|
        stmt.object
      end
    end

    def query *args, &block
      graph.query *args, &block
    end

    def reload
      Ldp::Orm.new resource.reload
    end

    def create
      nil
    end

    def save
      resource.update

      diff = self.class.check_for_differences_and_reload_resource self

      if diff.empty?
        true
      else
        diff
      end
    end

    def save!
      result = save

      if result.is_a? RDF::Graph
        raise GraphDifferenceException.new "", diff
      end

      result
    end

    def delete
      resource.delete
    end

    def method_missing meth, *args, &block
      super
    end

    def respond_to?(meth)
      super
    end

    def self.check_for_differences_and_reload_resource old_object
      new_object = old_object.reload

      bijection = new_object.graph.bijection_to(old_object.graph)
      diff = RDF::Graph.new

      old_object.graph.each do |statement|
        if statement.has_blank_nodes?
          subject = bijection.fetch(statement.subject, false) if statement.subject.node?
          object = bijection.fetch(statement.object, false) if statement.object.node?
          bijection_statement = RDF::Statement.new :subject => subject || statemnet.subject, :predicate => statement.predicate, :object => object || statement.object
          
          diff << statement if subject === false or object === false or new_object.graph.has_statement?(bijection_statement)
        elsif !new_object.graph.has_statement? statement
          diff << statement
        end
      end

      diff
    end

  end

  class GraphDifferenceException < Exception
    attr_reader :diff
    def initialize message, diff
      super(message)
      self.diff = diff
    end

  end
end