require 'spec_helper'
require 'ld4l/open_annotation_rdf/vocab/dctypes'
require 'ld4l/open_annotation_rdf/vocab/oa'


describe 'LD4L::OpenAnnotationRDF::TagBody' do

  subject { LD4L::OpenAnnotationRDF::TagBody.new }

  describe 'rdf_subject' do
    it "should be a blank node if we haven't set it" do
      expect(subject.rdf_subject.node?).to be true
    end

    it "should be settable when it has not been set yet" do
      subject.set_subject! RDF::URI('http://example.org/moomin')
      expect(subject.rdf_subject).to eq RDF::URI('http://example.org/moomin')
    end

    it "should append to base URI when setting to non-URI subject" do
      subject.set_subject! '123'
      expect(subject.rdf_subject).to eq RDF::URI("#{LD4L::OpenAnnotationRDF::TagBody.base_uri}123")
    end

    describe 'when changing subject' do
      before do
        subject << RDF::Statement.new(subject.rdf_subject, RDF::DC.title, RDF::Literal('Comet in Moominland'))
        subject << RDF::Statement.new(RDF::URI('http://example.org/moomin_comics'), RDF::DC.isPartOf, subject.rdf_subject)
        subject << RDF::Statement.new(RDF::URI('http://example.org/moomin_comics'), RDF::DC.relation, 'http://example.org/moomin_land')
        subject.set_subject! RDF::URI('http://example.org/moomin')
      end

      it 'should update graph subjects' do
        expect(subject.has_statement?(RDF::Statement.new(subject.rdf_subject, RDF::DC.title, RDF::Literal('Comet in Moominland')))).to be true
      end

      it 'should update graph objects' do
        expect(subject.has_statement?(RDF::Statement.new(RDF::URI('http://example.org/moomin_comics'), RDF::DC.isPartOf, subject.rdf_subject))).to be true
      end

      it 'should leave other uris alone' do
        expect(subject.has_statement?(RDF::Statement.new(RDF::URI('http://example.org/moomin_comics'), RDF::DC.relation, 'http://example.org/moomin_land'))).to be true
      end
    end

    describe 'created with URI subject' do
      before do
        subject.set_subject! RDF::URI('http://example.org/moomin')
      end

      it 'should not be settable' do
        expect{ subject.set_subject! RDF::URI('http://example.org/moomin2') }.to raise_error
      end
    end
  end


  # -------------------------------------------------
  #  START -- Test attributes specific to this model
  # -------------------------------------------------

  describe 'type' do
    it "should be set to text and astext from new" do
      expect(subject.type.size).to eq 2
      expect(subject.type).to include RDFVocabularies::OA.Tag
      expect(subject.type).to include RDFVocabularies::CNT.ContentAsText
    end
  end

  describe 'tag' do
    it "should be empty array if we haven't set it" do
      expect(subject.tag).to match_array([])
    end

    it "should be settable" do
      subject.tag = "good"
      expect(subject.tag).to eq ["good"]
    end

    it "should be changeable" do
      subject.tag = "good"
      subject.tag = "new_good"
      expect(subject.tag).to eq ["new_good"]
    end
  end

  describe "#annotations_using" do

    context "when tag value is nil" do
      it "should throw invalid arguement exception" do
        expect{ LD4L::OpenAnnotationRDF::TagBody.annotations_using(nil) }.to raise_error
      end
    end

    context "when tag value is a string of 0 length" do
      it "should throw invalid arguement exception" do
        expect{ LD4L::OpenAnnotationRDF::TagBody.annotations_using("") }.to raise_error
      end
    end

    context "when tag value is not a string" do
      it "should throw invalid arguement exception" do
        expect{ LD4L::OpenAnnotationRDF::TagBody.annotations_using(3) }.to raise_error
      end
    end

    context "when tags exist in the repository" do
      before(:all) do
        # Create inmemory repository
        ta = LD4L::OpenAnnotationRDF::TagAnnotation.new('http://example.org/ta1')
        ta.setTag('EXISTING_tag')
        ta.persist!
        ta = LD4L::OpenAnnotationRDF::TagAnnotation.new('http://example.org/ta2')
        ta.setTag('EXISTING_tag')
        ta.persist!
        tb = LD4L::OpenAnnotationRDF::TagBody.new('http://example.org/UNUSED_tag')
        tb.tag = 'UNUSED_tag'
        tb.persist!
      end
      after(:all) do
        LD4L::OpenAnnotationRDF::TagAnnotation.new('http://example.org/ta1').destroy!
        LD4L::OpenAnnotationRDF::TagAnnotation.new('http://example.org/ta2').destroy!
        LD4L::OpenAnnotationRDF::TagBody.new('http://example.org/UNUSED_tag').destroy!
      end

      it "should find annotations using a tag" do
        annotations = LD4L::OpenAnnotationRDF::TagBody.annotations_using('EXISTING_tag')
        expect( annotations.include?(RDF::URI('http://example.org/ta1')) ).to be true
        expect( annotations.include?(RDF::URI('http://example.org/ta2')) ).to be true
        expect( annotations.size ).to be 2
      end

      it "should find 0 annotations for unused tag" do
        annotations = LD4L::OpenAnnotationRDF::TagBody.annotations_using('UNUSED_tag')
        expect( annotations ).to eq []
      end

      it "should find 0 annotations for non-existent tag" do
        annotations = LD4L::OpenAnnotationRDF::TagBody.annotations_using('NONEXISTING_tag')
        expect( annotations ).to eq []
      end
    end
  end

  describe "#fetch_by_tag_value" do

    context "when new value is nil" do
      it "should throw invalid arguement exception" do
        expect{ LD4L::OpenAnnotationRDF::TagBody.fetch_by_tag_value(nil) }.to raise_error
      end
    end

    context "when new value is a string of 0 length" do
      it "should throw invalid arguement exception" do
        expect{ LD4L::OpenAnnotationRDF::TagBody.fetch_by_tag_value("") }.to raise_error
      end
    end

    context "when new value is not a string" do
      it "should throw invalid arguement exception" do
        expect{ LD4L::OpenAnnotationRDF::TagBody.fetch_by_tag_value(3) }.to raise_error
      end
    end

    context "when tags exist in the repository" do
      before(:all) do
        # Create inmemory repository
        ta = LD4L::OpenAnnotationRDF::TagAnnotation.new('http://example.org/ta1')
        ta.setTag('EXISTING_tag')
        ta.persist!
        ta = LD4L::OpenAnnotationRDF::TagAnnotation.new('http://example.org/ta2')
        ta.setTag('EXISTING_tag')
        ta.persist!
        tb = LD4L::OpenAnnotationRDF::TagBody.new('http://example.org/UNUSED_tag')
        tb.tag = 'UNUSED_tag'
        tb.persist!
      end
      after(:all) do
        LD4L::OpenAnnotationRDF::TagAnnotation.new('http://example.org/ta1').destroy!
        LD4L::OpenAnnotationRDF::TagAnnotation.new('http://example.org/ta2').destroy!
        LD4L::OpenAnnotationRDF::TagBody.new('http://example.org/UNUSED_tag').destroy!
      end

      it "should not find non-existent tag" do
        expect( LD4L::OpenAnnotationRDF::TagBody.fetch_by_tag_value('NONEXISTING_tag') ).to be_nil
      end

      it "should not find existent tag even if not referenced in an annotation" do
        tb = LD4L::OpenAnnotationRDF::TagBody.fetch_by_tag_value('UNUSED_tag')
        expect( tb ).not_to be_nil
        expect( tb.rdf_subject.to_s ).to eq 'http://example.org/UNUSED_tag'
      end

      it "should find same existing tag body each time called" do
        tb1 = LD4L::OpenAnnotationRDF::TagBody.fetch_by_tag_value('EXISTING_tag')
        tb2 = LD4L::OpenAnnotationRDF::TagBody.fetch_by_tag_value('EXISTING_tag')
        expect(tb2.rdf_subject).to eq tb1.rdf_subject
      end
    end
  end

  describe '#localname_prefix' do
    it "should return default prefix" do
      prefix = LD4L::OpenAnnotationRDF::TagBody.localname_prefix
      expect(prefix).to eq "tb"
    end
  end

  # -----------------------------------------------
  #  END -- Test attributes specific to this model
  # -----------------------------------------------


  describe "#persisted?" do
    context 'with a repository' do
      before do
        # Create inmemory repository
        repository = RDF::Repository.new
        allow(subject).to receive(:repository).and_return(repository)
      end

      context "when the object is new" do
        it "should return false" do
          expect(subject).not_to be_persisted
        end
      end

      context "when it is saved" do
        before do
          subject.tag = "bla"
          subject.persist!
        end

        it "should return true" do
          expect(subject).to be_persisted
        end

        context "and then modified" do
          before do
            subject.tag = "newbla"
          end

          it "should return true" do
            expect(subject).to be_persisted
          end
        end
        context "and then reloaded" do
          before do
            subject.reload
          end

          it "should reset the tag" do
            expect(subject.tag).to eq ["bla"]
          end

          it "should be persisted" do
            expect(subject).to be_persisted
          end
        end
      end
    end
  end

  describe "#persist!" do
    context "when the repository is set" do
      context "and the item is not a blank node" do

        subject {LD4L::OpenAnnotationRDF::TagBody.new("123")}

        before do
          # Create inmemory repository
          @repo = RDF::Repository.new
          allow(subject.class).to receive(:repository).and_return(nil)
          allow(subject).to receive(:repository).and_return(@repo)
          subject.tag = "bla"
          subject.persist!
        end

        it "should persist to the repository" do
          expect(@repo.statements.first).to eq subject.statements.first
        end

        it "should delete from the repository" do
          subject.reload
          expect(subject.tag).to eq ["bla"]
          subject.tag = []
          expect(subject.tag).to eq []
          subject.persist!
          subject.reload
          expect(subject.tag).to eq []
          expect(@repo.statements.to_a.length).to eq 2 # Only the 2 type statements
        end
      end
    end
  end

  describe '#destroy!' do
    before do
      subject << RDF::Statement(RDF::DC.LicenseDocument, RDF::DC.title, 'LICENSE')
    end

    subject { LD4L::OpenAnnotationRDF::TagBody.new('456')}

    it 'should return true' do
      expect(subject.destroy!).to be true
      expect(subject.destroy).to be true
    end

    it 'should delete the graph' do
      subject.destroy
      expect(subject).to be_empty
    end
  end

  describe '#rdf_label' do
    subject {LD4L::OpenAnnotationRDF::TagBody.new("123")}

    it 'should return an array of label values' do
      expect(subject.rdf_label).to be_kind_of Array
    end

    it 'should return the default label as URI when no title property exists' do
      expect(subject.rdf_label).to eq [RDF::URI("#{LD4L::OpenAnnotationRDF::TagBody.base_uri}123")]
    end

    it 'should prioritize configured label values' do
      custom_label = RDF::URI('http://example.org/custom_label')
      subject.class.configure :rdf_label => custom_label
      subject << RDF::Statement(subject.rdf_subject, custom_label, RDF::Literal('New Label'))
      expect(subject.rdf_label).to eq ['New Label']
    end
  end

  describe '#solrize' do
    it 'should return a label for bnodes' do
      expect(subject.solrize).to eq subject.rdf_label
    end

    it 'should return a string of the resource uri' do
      subject.set_subject! 'http://example.org/moomin'
      expect(subject.solrize).to eq 'http://example.org/moomin'
    end
  end

  describe 'editing the graph' do
    it 'should write properties when statements are added' do
      subject << RDF::Statement.new(subject.rdf_subject, RDFVocabularies::CNT.chars, 'good')
      expect(subject.tag).to include 'good'
    end

    it 'should delete properties when statements are removed' do
      subject << RDF::Statement.new(subject.rdf_subject, RDFVocabularies::CNT.chars, 'good')
      subject.delete RDF::Statement.new(subject.rdf_subject, RDFVocabularies::CNT.chars, 'good')
      expect(subject.tag).to eq []
    end
  end

  describe 'big complex graphs' do
    before do
      class DummyPerson < ActiveTriples::Resource
        configure :type => RDF::URI('http://example.org/Person')
        property :foafname, :predicate => RDF::FOAF.name
        property :publications, :predicate => RDF::FOAF.publications, :class_name => 'DummyDocument'
        property :knows, :predicate => RDF::FOAF.knows, :class_name => DummyPerson
      end

      class DummyDocument < ActiveTriples::Resource
        configure :type => RDF::URI('http://example.org/Document')
        property :title, :predicate => RDF::DC.title
        property :creator, :predicate => RDF::DC.creator, :class_name => 'DummyPerson'
      end

      LD4L::OpenAnnotationRDF::TagBody.property :item, :predicate => RDF::DC.relation, :class_name => DummyDocument
    end

    subject { LD4L::OpenAnnotationRDF::TagBody.new }

    let (:document1) do
      d = DummyDocument.new
      d.title = 'Document One'
      d
    end

    let (:document2) do
      d = DummyDocument.new
      d.title = 'Document Two'
      d
    end

    let (:person1) do
      p = DummyPerson.new
      p.foafname = 'Alice'
      p
    end

    let (:person2) do
      p = DummyPerson.new
      p.foafname = 'Bob'
      p
    end

    let (:data) { <<END
_:1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/SomeClass> .
_:1 <http://purl.org/dc/terms/relation> _:2 .
_:2 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/Document> .
_:2 <http://purl.org/dc/terms/title> "Document One" .
_:2 <http://purl.org/dc/terms/creator> _:3 .
_:2 <http://purl.org/dc/terms/creator> _:4 .
_:4 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/Person> .
_:4 <http://xmlns.com/foaf/0.1/name> "Bob" .
_:3 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/Person> .
_:3 <http://xmlns.com/foaf/0.1/name> "Alice" .
_:3 <http://xmlns.com/foaf/0.1/knows> _:4 ."
END
    }

    after do
      Object.send(:remove_const, "DummyDocument")
      Object.send(:remove_const, "DummyPerson")
    end

    it 'should allow access to deep nodes' do
      document1.creator = [person1, person2]
      document2.creator = person1
      person1.knows = person2
      subject.item = [document1]
      expect(subject.item.first.creator.first.knows.first.foafname).to eq ['Bob']
    end
  end
end
