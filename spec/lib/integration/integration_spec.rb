require 'spec_helper'
require 'lamprey'
require 'securerandom'

describe 'RDF::Lamprey' do
  let(:server) { @runner.server }
  let(:lamprey) { server.app }
  let(:repository) { lamprey.settings.repository }
  let(:debug) { ENV.fetch('DEBUG', false) }
  let(:client) do
    Faraday.new(url: server.url) do |faraday|
      faraday.response :logger if debug
      faraday.adapter Faraday.default_adapter
    end
  end
  let(:ldp_client) { Ldp::Client.new(client, repository: repository) }

  before(:context) do
    @runner = Ldp::Runner.new(RDF::Lamprey)
    @runner.boot
  end

  describe 'Ldp::Resource::RdfSource#create' do
    let(:uri) { '/rdf_source' }
    let(:rdf_source) { Ldp::Resource::RdfSource.new(ldp_client, uri) }

    before do
      rdf_source.create
    end

    it 'creates resources' do
      expect(rdf_source.new?).to be false
      expect(rdf_source.subject).to eq(uri)
    end
  end

  describe 'Ldp::Resource::BinarySource#create' do
    let(:uri) { '/binary_source' }
    let(:binary_source) { Ldp::Resource::BinarySource.new(ldp_client, uri, 'abcdef') }

    before do
      binary_source.create
    end

    it 'creates binary resources' do
      expect(binary_source.new?).to be false
      expect(binary_source.subject).to eq(uri)
    end
  end

  describe 'Ldp::Container::Basic#create' do
    let(:uri) { '/basic_container' }
    let(:basic_container) { Ldp::Container::Basic.new(ldp_client, uri) }

    before do
      basic_container.create
    end

    it 'creates basic containers' do
      expect(basic_container.new?).to be false
      expect(basic_container.subject).to eq(uri)
    end
  end

  describe 'Ldp::Container::Direct#create' do
    let(:uri) { '/direct_container' }
    let(:direct_container) { Ldp::Container::Direct.new(ldp_client, uri) }

    before do
      direct_container.create
    end

    it 'creates direct containers' do
      expect(direct_container.new?).to be false
      expect(direct_container.subject).to eq(uri)
    end
  end

  describe 'Ldp::Container::Indirect#create' do
    let(:uri) { '/indirect_container' }
    let(:indirect_container) { Ldp::Container::Indirect.new(ldp_client, uri) }

    before do
      indirect_container.create
    end

    it 'creates indirect containers' do
      expect(indirect_container.new?).to be false
      expect(indirect_container.subject).to eq(uri)
    end
  end
end
