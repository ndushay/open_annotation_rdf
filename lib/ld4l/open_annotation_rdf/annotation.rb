module LD4L
  module OpenAnnotationRDF
    class Annotation < ActiveTriples::Resource

      class << self; attr_reader :localname_prefix end
      @localname_prefix="oa"

      @body = nil

      configure :type => RDFVocabularies::OA.Annotation,
                :base_uri => LD4L::OpenAnnotationRDF.configuration.base_uri,
                :repository => :default

      property :hasTarget,   :predicate => RDFVocabularies::OA.hasTarget    # :type => URI
      property :hasBody,     :predicate => RDFVocabularies::OA.hasBody
      property :annotatedBy, :predicate => RDFVocabularies::OA.annotatedBy, :class_name => LD4L::FoafRDF::Person
      property :annotatedAt, :predicate => RDFVocabularies::OA.annotatedAt, :cast => false   # :type => xsd:dateTime    # the time Annotation was created
      property :motivatedBy, :predicate => RDFVocabularies::OA.motivatedBy, :cast => false   # comes from RDFVocabularies::OA ontology

      def self.resume(uri_or_str)
        # Let ActiveTriples::Resource validate uri_or_str when creating new Annotation
        a = new(uri_or_str)

        # get motivatedBy
        m = a.get_values(:motivatedBy)
        # TODO:  Should m's class be validated?  I've seen it be RDF::Vocabulary::Term and RDF::URI.  For now, removing the validation.
        return a    unless m.kind_of?(Array) && m.size > 0
        # return a    unless m.kind_of?(Array) && m.size > 0 && (m.first.kind_of?(RDF::Vocabulary::Term) || m.first.kind_of?(RDF::URI)

        # motivatedBy is set
        m_uri = m.first
        # currently only support commenting and tagging
        return LD4L::OpenAnnotationRDF::CommentAnnotation.new(uri_or_str) if m_uri == RDFVocabularies::OA.commenting
        return a                                                       unless m_uri == RDFVocabularies::OA.tagging

        # Tagging can be TagAnnotation or SemanticTagAnnotation.  Only way to tell is by checking type of body.
        sta = LD4L::OpenAnnotationRDF::SemanticTagAnnotation.new(uri_or_str)
        stb = sta.getBody
        return sta                          if stb.type.include?(RDFVocabularies::OA.SemanticTag)

        ta = LD4L::OpenAnnotationRDF::TagAnnotation.new(uri_or_str)
        tb = ta.getBody
        return ta                           if tb.type.include?(RDFVocabularies::OA.Tag)

        # can't match to a known annotation type, so return as generic annotation
        return a
      end

      ##
      # Get the <tt>ActiveTriples::Resource</tt> instance holding the body of this annotation.
      #
      # @param [String] tag value
      #
      # @return instance of an annotation body if one is set; otherwise, nil
      def getBody
        @body
      end

      ##
      # Set annotatedAt property to now.
      #
      # @return the value of annotatedAt property
      def setAnnotatedAtNow
        set_value(:annotatedAt, Time.now.utc.iso8601(0))
      end

      ##
      # Save all annotation and annotation body triples to the triple store.
      #
      # @return true if annotation successfully persisted; otherwise, false
      #
      # @todo What to return if annotation persists fine, but body fails to persist?
      def persist!
        persisted = super                                               # persist annotation
        body_persisted = persisted && @body ? @body.persist! : false    # persist body
        persisted
      end

      ##
      # Find annotation by target.
      #
      # @param [String, RDF::URI] uri for the work
      #
      # @return true if annotation successfully persisted; otherwise, false
      #
      # @todo What to return if annotation persists fine, but body fails to persist?
      def self::find_by_target(target_uri)
        raise ArgumentError, 'target_uri argument must be a uri string or an instance of RDF::URI'  unless
            target_uri.kind_of?(String) && target_uri.size > 0 || target_uri.kind_of?(RDF::URI)

        # raise ArgumentError, 'repository argument must be an instance of RDF::Repository'  unless
        #     repository.kind_of?(RDF::Repository)

        target_uri = RDF::URI(target_uri) unless target_uri.kind_of?(RDF::URI)

        repo = ActiveTriples::Repositories.repositories[repository]
        query = RDF::Query.new({
                                   :annotation => {
                                       RDF.type =>  RDFVocabularies::OA.Annotation,
                                       RDFVocabularies::OA.hasTarget => target_uri,
                                   }
                               })
        annotations = []
        results = query.execute(repo)
        results.each { |r| annotations << r.to_hash[:annotation] }
        annotations
      end
    end
  end
end

