require 'spec_helper'

require 'capybara_discoball'
require 'derby/server'

describe 'Integration tests' do
  before(:all) do
    WebMock.disable!
  end

  after(:all) do
    WebMock.enable!
  end

  subject(:ldp_client) { Ldp::Client.default }

  let(:client_url) do
    "http://#{ENV['FCREPO_HOST']}:#{ENV['FCREPO_PORT']}/rest"
  end

  let(:base_path) { client_url }

  let(:debug) { ENV.fetch('DEBUG', false) }

  let(:client) do
    Faraday.new(url: client_url) do |faraday|
      faraday.response :logger if debug
      faraday.adapter Faraday.default_adapter
    end
  end

  let(:client_response) { nil }
  let(:resource_subject) { '/' }
  let(:resource_tombstone) { "#{base_path}/#{resource_subject}/fcr:tombstone" }
  let(:persisted) { ldp_client.find_or_initialize(resource_subject) }

  before do
    client.delete(resource_tombstone)
    persisted.delete unless persisted.nil? || persisted.root? || persisted.new?
  end

  after do
    persisted = ldp_client.find_or_initialize(resource_subject)
    persisted.delete unless persisted.nil?
    client.delete(resource_tombstone)
  end

  context "when creating a RDF source" do
    let(:resource_subject) { '/rdf_source' }
    let(:content) { nil }

    before do
      rdf_source = Ldp::Resource::RdfSource.new(ldp_client, resource_subject, content, base_path)
      rdf_source.create
    end

    it 'can find the persisted RDF sources' do
      obj = ldp_client.find_or_initialize(resource_subject)
      expect(obj).not_to be_new
      expect(obj).to be_a_kind_of Ldp::Resource::RdfSource
    end
  end

  context "when creating a binary source" do
    let(:resource_subject) { '/binary_source' }
    let(:content) { 'abcdef' }

    before do
      binary_source = Ldp::Resource::BinarySource.new(ldp_client, resource_subject, content, base_path)
      binary_source.create
    end

    it 'can find the persisted binary sources' do
      obj = ldp_client.find_or_initialize(resource_subject)
      expect(obj).not_to be_new
      expect(obj).to be_a_kind_of Ldp::Resource::BinarySource
    end
  end

  context "when creating a basic container" do
    let(:resource_subject) { '/basic_container' }

    before do
      basic_container = Ldp::Container::Basic.new(ldp_client, resource_subject, client_response, base_path)
      basic_container.create
    end

    it 'can find the persisted basic container' do
      obj = ldp_client.find_or_initialize(resource_subject)
      expect(obj).not_to be_new
      expect(obj).to be_a_kind_of Ldp::Container::Basic
    end
  end

  context "when creating a direct container" do
    let(:resource_subject) { '/direct_container' }

    before do
      direct_container = Ldp::Container::Direct.new(ldp_client, resource_subject, client_response, base_path)
      direct_container.create
    end

    it 'can find the persisted direct containers' do
      obj = ldp_client.find_or_initialize(resource_subject)
      expect(obj).not_to be_new
      expect(obj).to be_a_kind_of Ldp::Container
      expect(obj).to be_a_kind_of Ldp::Container::Basic
      # This is not working properly with fcrepo
      # expect(obj).to be_a_kind_of Ldp::Container::Direct
    end
  end

  context "when creating an indirect container" do
    let(:resource_subject) { '/indirect_container' }

    before do
      indirect_container = Ldp::Container::Indirect.new(ldp_client, resource_subject, client_response, base_path)
      indirect_container.create
    end

    it 'creates indirect containers' do
      obj = ldp_client.find_or_initialize(resource_subject)
      expect(obj).not_to be_new
      expect(obj).to be_a_kind_of Ldp::Container
      expect(obj).to be_a_kind_of Ldp::Container::Basic
      # This is not working properly with fcrepo
      # expect(obj).to be_a_kind_of Ldp::Container::Indirect
    end
  end
end
