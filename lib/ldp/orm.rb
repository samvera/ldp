module Ldp
  class Orm

    attr_reader :resource
    attr_reader :last_response

    def initialize resource
      @resource = resource
    end

    def subject_uri
      resource.subject_uri
    end

    def new?
      resource.new?
    end

    def persisted?
      !new?
    end

    def graph
      Ldp.instrument 'graph.orm.ldp', subject: subject_uri do
        resource.graph
      end
    end

    def value predicate
      graph.query(:subject => subject_uri, :predicate => predicate).map do |stmt|
        stmt.object
      end
    end

    def query *args, &block
      Ldp.instrument 'query.orm.ldp', subject: subject_uri do
        graph.query *args, &block
      end
    end

    def reload
      Ldp.instrument 'reload.orm.ldp', subject: subject_uri do
        Ldp::Orm.new resource.reload
      end
    end

    def create
      Ldp.instrument 'create.orm.ldp', subject: subject_uri do
        # resource.create returns a reloaded resource which causes any default URIs (e.g. "<>")
        # in the graph to be transformed to routable URIs
        Ldp::Orm.new resource.create
      end
    end

    def save
      Ldp.instrument 'save.orm.ldp', subject: subject_uri do
        @last_response = resource.save
        @last_response.success?
      end
    rescue Ldp::HttpError => e
      @last_response = e
      logger.debug e
      false
    end

    def save!
      result = save

      if result.is_a? RDF::Enumerable
        raise GraphDifferenceException.new "", result
      elsif !result
        raise @last_response
      end

      result
    end

    def delete
      Ldp.instrument 'delete.orm.ldp', subject: subject_uri do
        resource.delete
      end
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
end
