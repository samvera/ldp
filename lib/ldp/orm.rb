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
      @last_response = resource.update

      diff = Ldp::Resource.check_for_differences_and_reload_resource self

      if diff.any?
        diff
      elsif @last_response.success?
        true
      else
        false
      end
    end

    def save!
      result = save

      if result.is_a? RDF::Graph
        raise GraphDifferenceException.new "", result
      elsif !result
        raise SaveException.new "", @last_response
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

  end

  class GraphDifferenceException < Exception
    attr_reader :diff
    def initialize message, diff
      super(message)
      @diff = diff
    end
  end

  class SaveException < Exception
    attr_reader :response
    def initialize message, response
      super(message)
      @response = response
    end
  end
end
