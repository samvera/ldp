module Ldp
  module Response::Paging  
    ##
    # Statements about the page
    def page
      @page_graph ||= begin
        g = RDF::Graph.new  

        if resource?
          res = graph.query RDF::Statement.new(page_subject, nil, nil)

          res.each_statement do |s|
            g << s
          end
        end

        g
      end
    end
    
    ##
    # Get the subject for the response
    def subject
      @subject ||= if has_page?
        graph.first_object [page_subject, Ldp.page_of, nil]
      else
        page_subject
      end
    end

    ##
    # Is there a next page?
    def has_next?
      next_page != nil
    end

    ##
    # Get the URI for the next page
    def next_page
      graph.first_object [page_subject, Ldp.nextPage, nil]
    end

    ##
    # Get the URI to the first page
    def first_page
      if links['first']
        RDF::URI.new links['first']
      elsif graph.has_statement? RDf::Statement.new(page_subject, Ldp.nextPage, nil)
        subject
      end
    end

    def sort

    end
  end 
end
