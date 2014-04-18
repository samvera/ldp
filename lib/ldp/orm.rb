module Ldp
  class Orm

    attr_reader :resource
    attr_reader :last_response

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
      # resource.create returns a reloaded resource which causes any default URIs (e.g. "<>")
      # in the graph to be transformed to routable URIs
      Ldp::Orm.new resource.create
    end

    def save
      @last_response = resource.update

      diff = resource.check_for_differences_and_reload

      if diff.any?
        diff
      else
        @last_response.success?
      end
    rescue Ldp::HttpError => e
      @last_response = e
      logger.debug e
      false
    end

    def save!
      result = save

      if result.is_a? RDF::Graph
        raise GraphDifferenceException.new "", result
      elsif !result
        raise SaveException.new @last_response
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

    private

    def logger
      Ldp.logger
    end
  end

  class GraphDifferenceException < Exception
    attr_reader :diff
    def initialize message, diff
      super(message)
      @diff = diff
    end
  end

  class SaveException < RuntimeError
  end
end
