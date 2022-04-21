require 'spec_helper'
require 'rdf/vocab'
require 'lamprey'

describe Ldp::Container do
  subject(:client) { instance_double(Ldp::Client) }

  describe '#contains' do
    let(:response) { double }
    let(:data) { Ldp::Response.new(response) }
    let(:types) { [RDF::Vocab::LDP.BasicContainer] }
    #let(:subject_uri) { ::URI.parse("http://localhost.localdomain#test") }
    let(:subject_uri) { "/test" }

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
    let(:container) { described_class.for(client, subject_uri, data) }

    before(:context) do
      @runner = Ldp::Runner.new(RDF::Lamprey)
      @runner.boot
    end

    let(:subject_source) { Ldp::Resource::RdfSource.new(client, subject_uri) }

    before do
      allow(data).to receive(:types).and_return(types)

      binding.pry
      subject_source.create
    end

    it 'constructs a Hash with RDF source objects' do
      binding.pry
      container.contains
      binding.pry

    end
  end

  describe '.for' do
    let(:response) { double }
    let(:data) { Ldp::Response.new(response) }
    let(:subject_uri) { ::URI.parse("http://localhost.localdomain#test") }
    let(:container) { described_class.for(client, subject_uri, data) }

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
