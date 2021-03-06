require 'spec_helper'

describe DataMapper::Serializer, '#to_yaml' do
  #
  # ==== yummy YAML
  #

  before(:all) do
    DataMapper.finalize
    @harness = Class.new(SerializerTestHarness) do
      def method_name
        :to_yaml
      end

      def deserialize(result)
        result = YAML.load(result)
        process = lambda {|object|
          if object.is_a?(Array)
            object.collect(&process)
          elsif object.is_a?(Hash)
            object.inject({}) {|a, (key, value)| a.update(key.to_s => process[value]) }
          else
            object
          end
        }
        process[result]
      end
    end.new

    @ruby_192 = RUBY_VERSION >= '1.9.2'
    @to_yaml  = true
  end

  include_examples 'A serialization method'
  include_examples 'A serialization method that also serializes core classes'

  it 'should allow static YAML dumping' do
    object = Cow.create(
      :id        => 89,
      :composite => 34,
      :name      => 'Berta',
      :breed     => 'Guernsey'
    )
    result = @harness.deserialize(YAML.dump(object))
    expect(result['name']).to eq('Berta')
  end

  it 'should allow static YAML dumping of a collection' do
    object = Cow.create(
      :id        => 89,
      :composite => 34,
      :name      => 'Berta',
      :breed     => 'Guernsey'
    )
    result = @harness.deserialize(YAML.dump(Cow.all))
    expect(result[0]['name']).to eq('Berta')
  end

end
