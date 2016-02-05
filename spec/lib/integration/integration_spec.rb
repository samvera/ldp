require 'spec_helper'
require 'capybara_discoball'
require 'derby/server'

describe 'Integration tests' do
  let!(:derby_server) do
    Capybara::Discoball::Runner.new(Derby::Server).boot
  end

  let(:debug) { ENV.fetch('DEBUG', false) }

  let(:client) do
    Faraday.new(url: derby_server) do |faraday|
      faraday.response :logger if debug
      faraday.adapter Faraday.default_adapter
    end
  end

  subject { Ldp::Client.new client }

  it 'creates resources' do
    subject.put '/rdf_source', ''
    obj = subject.find_or_initialize('/rdf_source')
    expect(obj).to be_a_kind_of Ldp::Resource::RdfSource
  end

  it 'creates binary resources' do
    Ldp::Resource::BinarySource.new(subject, '/binary_source', 'abcdef').create

    obj = subject.find_or_initialize('binary_source')
    expect(obj).to be_a_kind_of Ldp::Resource::BinarySource
  end

  it 'creates basic containers' do
    Ldp::Container::Basic.new(subject, '/basic_container').create
    obj = subject.find_or_initialize('/basic_container')
    expect(obj).not_to be_new
    expect(obj).to be_a_kind_of Ldp::Container::Basic
  end

  it 'creates direct containers' do
    Ldp::Container::Direct.new(subject, '/direct_container').create
    obj = subject.find_or_initialize('/direct_container')
    expect(obj).not_to be_new
    expect(obj).to be_a_kind_of Ldp::Container::Direct
  end

  it 'creates indirect containers' do
    Ldp::Container::Indirect.new(subject, '/indirect_container').create
    obj = subject.find_or_initialize('/indirect_container')
    expect(obj).not_to be_new
    expect(obj).to be_a_kind_of Ldp::Container::Indirect
  end
end
