require 'spec_helper'

describe Ldp::Resource::BinarySource do
  let(:client) { instance_double(Ldp::Client) }
  let(:uri) { 'http://example.com/foo/bar' }
  let(:content) { 'somecontent' }
  subject { described_class.new(client, uri, content) }

  it "should not display content to inspect" do
    expect(subject.inspect).to match /subject=\"http:\/\/example\.com\/foo\/bar\"/
    expect(subject.inspect).not_to match /somecontent/
  end

  describe '#described_by' do
    context 'without a description' do
      before do
        allow(client).to receive(:head).and_return(instance_double(Ldp::Response, links: { }))
      end

      it 'retrieves the description object' do
        expect(subject.described_by).to eq nil
      end
    end

    context 'with a description' do
      before do
        allow(client).to receive(:head).and_return(instance_double(Ldp::Response, links: { 'describedby' => ['http://example.com/foo/bar/desc']}))
        allow(client).to receive(:find_or_initialize).with('http://example.com/foo/bar/desc').and_return(desc)
      end

      let(:desc) { double }

      it 'retrieves the description object' do
        expect(subject.described_by).to eq desc
      end
    end
  end
end
