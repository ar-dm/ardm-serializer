require 'spec_helper'

describe DataMapper::Serializer, '#to_json' do
  #
  # ==== ajaxy JSON
  #

  before :all do
    DataMapper.finalize
    DataMapper.auto_migrate!
  end

  before :each do
    query = DataMapper::Query.new(DataMapper::repository(:default), Cow)

    keys = %w[ id composite name breed ]

    resources = [
      Hash[ keys.zip([  1,  2, 'Betsy', 'Jersey'   ]) ],
      Hash[ keys.zip([ 10, 20, 'Berta', 'Guernsey' ]) ],
    ]

    @collection = DataMapper::Collection.new(query, query.model.load(resources, query))

    @harness = Class.new(SerializerTestHarness) do
      def method_name
        :to_json
      end

      protected

      def deserialize(result)
        JSON.parse(result)
      end
    end.new
  end

  include_examples "A serialization method"
  include_examples 'A serialization method that also serializes core classes'

  it "handles options given to a collection properly" do
    deserialized_collection = JSON.parse(@collection.to_json(:only => [:composite]))
    betsy = deserialized_collection.first
    berta = deserialized_collection.last

    expect(betsy["id"]).to be_nil
    expect(betsy["composite"]).to eq(2)
    expect(betsy["name"]).to be_nil
    expect(betsy["breed"]).to be_nil

    expect(berta["id"]).to be_nil
    expect(berta["composite"]).to eq(20)
    expect(berta["name"]).to be_nil
    expect(berta["breed"]).to be_nil
  end

  it "supports :include option for one level depth"

  it "supports :include option for more than one level depth"

  it "has :repository option to override used repository"

  it "can be serialized within a Hash" do
    hash = { 'cows' => Cow.all }
    expect(JSON.parse(hash.to_json)).to eq(hash)
  end

end

describe DataMapper::Serializer, '#as_json' do
  it "handles nil for options" do
    expect { Cow.new.as_json(nil) }.to_not raise_error
  end

  it "serializes Discriminator types as strings" do
    expect(Motorcycle.new.as_json[:type]).to eq("Motorcycle")
  end
end
