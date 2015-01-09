require 'spec_helper'

describe Ldp::Resource::BinarySource do
  let(:client) { double }
  let(:uri) { 'http://example.com/foo/bar' }
  let(:content) { 'somecontent' }
  subject { described_class.new(client, uri, content) }

  it "should not display content to inspect" do
    expect(subject.inspect).to match /subject=\"http:\/\/example\.com\/foo\/bar\"/
    expect(subject.inspect).not_to match /somecontent/
  end

end
