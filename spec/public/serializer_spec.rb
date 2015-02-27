require 'spec_helper'

describe DataMapper::Serialize do
  it "is included into DataMapper::Resource" do
    expect(Cow.new).to be_kind_of(DataMapper::Serialize)
  end
end
