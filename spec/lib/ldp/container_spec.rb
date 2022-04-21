require 'spec_helper'
require 'rdf/vocab'
require 'lamprey'

describe Ldp::Container do
  let(:client) { instance_double(Ldp::Client) }

  let(:container_uri) { "/root" }
  describe '#contains' do
    let(:response) { double }
    let(:data) { Ldp::Response.new(response) }
    let(:types) { [RDF::Vocab::LDP.BasicContainer] }

    #let(:container_uri) { "/root" }
    let(:child_uri) { "/root/test" }

    let(:server) { @runner.server }
    let(:lamprey) { server.app }
    let(:repository) { lamprey.settings.repository }
    let(:debug) { ENV.fetch('DEBUG', false) }
    let(:http_client) do
      Faraday.new(url: server.url) do |faraday|
        faraday.response :logger if debug
        faraday.adapter Faraday.default_adapter
      end
    end
    let(:client) { Ldp::Client.new(http_client, repository: repository) }

    before(:context) do
      @runner = Ldp::Runner.new(RDF::Lamprey)
      @runner.boot
    end

    #let(:container) { Ldp::Resource::RdfSource.new(client, container_uri) }
    subject(:container) { described_class.new(client, container_uri) }
    let(:child_source) { Ldp::Resource::RdfSource.new(client, child_uri) }

    #subject(:container) { described_class.for(client, container_uri, data) }

    before do
      allow(data).to receive(:types).and_return(types)

      container.create unless container.persisted?
      child_source.create unless child_source.persisted?

      statement1 = RDF::Statement(container.uri, RDF::URI.parse("http://purl.org/dc/terms/title"), "test title")
      statement2 = RDF::Statement(container.uri, RDF::Vocab::LDP.contains, child_source.uri)

      statements = RDF::List[statement1, statement2]
      #container.add(statements)

      #children = RDF::List[child_source]
      container.add(child_source)
    end

    after do
      child_source.delete
      container.delete
    end

    it 'constructs a Hash with RDF source objects' do
      contained = container.contains

      expect(contained).to be_a(Hash)
      expect(contained).to include(child_source.uri)

      contained_source = contained[child_source.uri]
      expect(contained_source).to be_a(Ldp::Resource::RdfSource)
      expect(contained_source.uri).to eq(child_source.uri)
    end
  end

  describe '.for' do
    let(:response) { double }
    let(:data) { Ldp::Response.new(response) }
    let(:container) { described_class.for(client, container_uri, data) }

    before do
      allow(data).to receive(:types).and_return(types)
    end

    context 'when specifying an Indirect Container data type' do
      let(:types) { [RDF::Vocab::LDP.IndirectContainer] }

      it 'constructs an Ldp::Container::Indirect object' do
        expect(container).to be_a(Ldp::Container::Indirect)
      end
    end

    context 'when specifying an Direct Container data type' do
      let(:types) { [RDF::Vocab::LDP.DirectContainer] }

      it 'constructs an Ldp::Container::Direct object' do
        expect(container).to be_a(Ldp::Container::Direct)
      end
    end
  end
end
