module Jekyll

  ##
  #
  # JekyllRdf::Generator enriches site.data with rdf triples
  #
  class RdfMainGenerator < Jekyll::Generator
    safe true
    priority :highest

    ##
    # #generate performs the enrichment of site.data with rdf triples
    #
    # * +site+ - The site whose data is to be enriched
    #
    def generate(site)
      config = site.config.fetch('jekyll_rdf')

      graph = RDF::Graph.load(config['path'])
      sparql = SPARQL::Client.new(graph)

      # restrict RDF graph with restriction
      resources = extract_resources(config['restriction'], config['include_blank'], graph, sparql)

      site.data['resources'] = []

      mapper = Jekyll::RdfTemplateMapper.new(config['template_mappings'], config['default_template'])

      # create RDF pages for each URI
      resources.each do |uri|
        resource = Jekyll::Drops::RdfResource.new(uri, graph)
        site.pages << RdfPageData.new(site, site.source, resource, mapper)
      end
    end

    ##
    # #extract_resources restricts the RDF graph with given restriction arguments
    #
    # * +restriction+ - The option you want to restrict the RDF graph with - only subjects, objects, predicates or custom SPARQL query
    # * +graph+ - The RDF graph to restrict
    # * +sparql+ - The SPARQL client to run queries
    #
    def extract_resources(restriction, include_blank, graph, sparql)
      # Reject literals
      # Select URIs and blank nodes in case of include_blank
      object_resources = graph.objects.reject{ |o| o.class <= RDF::Literal }.select { |o| include_blank || o.class == RDF::URI }.uniq
      subject_resources = graph.subjects.reject{ |s| s.class <= RDF::Literal }.select { |s| include_blank || s.class == RDF::URI }.uniq
      predicate_resources = graph.predicates.reject{ |p| p.class <= RDF::Literal }.select { |p| include_blank || p.class == RDF::URI }.uniq

      # Config parameter not present
      unless restriction
        return object_resources.concat(subject_resources).concat(predicate_resources).uniq
      end

      case restriction
      when "objects"
        return object_resources
      when "subjects"
        return subject_resources
      when "predicates"
        return predicate_resources
      else
        # Custom query
        result = sparql.query(restriction).map{|sol| sol.each_value.first}
        return result.reject{ |s| s.class <= RDF::Literal }.select { |s| include_blank || s.class == RDF::URI }.uniq
      end
    end

  end

end