require 'active_triples/local_name'

module LD4L
  module OpenAnnotationRDF
    class CommentAnnotation < LD4L::OpenAnnotationRDF::Annotation
      @id_prefix="cm"

      property :hasBody, :predicate => RDFVocabularies::OA.hasBody, :class_name => LD4L::OpenAnnotationRDF::CommentBody


      ##
      # Create a comment annotation body and set the hasBody property to it.
      #
      # @param [String]
      #
      # @return instance of SemanticTagBody
      def setComment(comment)
        @body = LD4L::OpenAnnotationRDF::CommentBody.new(
            ActiveTriples::LocalName::Minter.generate_local_name(
                LD4L::OpenAnnotationRDF::CommentBody, 10, @id_prefix,
                LD4L::OpenAnnotationRDF.configuration.localname_minter ))
        @body.content = comment
        @body.format  = "text/plain"
        set_value(:hasBody, @body)
        @body
      end

      ##
      # Special processing for new and resumed CommentAnnotations
      #
      def initialize(*args)
        super(*args)

        # set motivatedBy
        m = get_values(:motivatedBy)
        set_value(:motivatedBy, RDFVocabularies::OA.commenting) unless m.kind_of?(Array) && m.size > 0

        # resume CommentBody if it exists
        comment_uri = get_values(:hasBody).first
        if( comment_uri )
          comment_uri = comment_uri.rdf_subject  if comment_uri.kind_of?(ActiveTriples::Resource)
          @body  = LD4L::OpenAnnotationRDF::CommentBody.new(comment_uri)
        end
      end
    end
  end
end

