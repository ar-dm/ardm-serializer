RSpec.shared_examples_for 'A serialization method that also serializes core classes' do
  # This spec ensures that we don't break any serialization methods attached
  # to core classes, such as Array
  before :each do
    %w[ @harness ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_get(ivar)
    end

    DataMapper.auto_migrate!
  end

  before :each do
    DataMapper::Model.descendants.each { |model| model.destroy! }
  end

  it 'serializes an array of extended objects' do
    Cow.create(
      :id        => 89,
      :composite => 34,
      :name      => 'Berta',
      :breed     => 'Guernsey'
    )
    result = @harness.test(Cow.all.to_a)
    expect(result[0].values_at("id", "composite", "name", "breed")).to eq(
      [89, 34, "Berta", "Guernsey"]
    )
  end

  it 'serializes an array of collections' do
    query = DataMapper::Query.new(DataMapper::repository(:default), Cow)

    keys = %w[ id composite name breed ]

    resources = [
      Hash[ keys.zip([  1,  2, 'Betsy', 'Jersey'   ]) ],
      Hash[ keys.zip([ 89, 34, 'Berta', 'Guernsey' ]) ],
    ]

    collection = DataMapper::Collection.new(query, query.model.load(resources, query))

    result = @harness.test(collection)
    expect(result[0].values_at(*keys)).to eq(resources[0].values_at(*keys))
    expect(result[1].values_at(*keys)).to eq(resources[1].values_at(*keys))
  end
end

RSpec.shared_examples_for 'A serialization method' do
  before :each do
    %w[ @harness ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_get(ivar)
    end

    DataMapper.auto_migrate!
  end

  before :each do
    DataMapper::Model.descendants.each { |model| model.destroy! }
  end

  describe '(serializing single resources)' do
    it 'should serialize Model.first' do
      # At the moment this is implied by serializing a resource, but this
      # test ensures the contract even if dm-core changes
      Cow.create(
        :id        => 89,
        :composite => 34,
        :name      => 'Berta',
        :breed     => 'Guernsey'
      )
      result = @harness.test(Cow.first)
      expect(result.values_at("name", "breed")).to eq(["Berta", "Guernsey"])
    end

    it 'should serialize a resource' do
      cow = Cow.new(
        :id        => 89,
        :composite => 34,
        :name      => 'Berta',
        :breed     => 'Guernsey'
      )

      result = @harness.test(cow)
      expect(result.values_at("id", "composite", "name", "breed")).to eq([89,  34, 'Berta', 'Guernsey'])
    end

    it 'should exclude nil properties' do
      cow = Cow.new(
        :id        => 89,
        :name      => nil
      )

      result = @harness.test(cow)
      expect(result.values_at("id", "composite")).to eq([89,  nil])
    end

    context "when supported" do
      before do
        skip 'Psych provides no way to pass in parameters' if @ruby_192 && @to_yaml
      end

      it "should only includes properties given to :only option" do
        planet = Planet.new(
          :name     => "Mars",
          :aphelion => 249_209_300.4
        )

        result = @harness.test(planet, :only => [:name])
        expect(result.values_at("name", "aphelion")).to eq(["Mars", nil])
      end

      it "should serialize values returned by an array of methods given to :methods option" do
        planet = Planet.new(
          :name     => "Mars",
          :aphelion => 249_209_300.4
        )

        result = @harness.test(planet, :methods => [:category, :has_known_form_of_life?])
        # XML currently can't serialize ? at the end of method names
        boolean_method_name = @harness.method_name == :to_xml ? "has_known_form_of_life" : "has_known_form_of_life?"
        expect(result.values_at("category", boolean_method_name)).to eq(["terrestrial", false])
      end

      it "should serialize values returned by a single method given to :methods option" do
        planet = Planet.new(
          :name     => "Mars",
          :aphelion => 249_209_300.4
        )

        result = @harness.test(planet, :methods => :category)
        expect(result.values_at("category")).to eq(["terrestrial"])
      end

      it "should only include properties given to :only option" do
        planet = Planet.new(
          :name     => "Mars",
          :aphelion => 249_209_300.4
        )

        result = @harness.test(planet, :only => [:name])
        expect(result.values_at("name", "aphelion")).to eq(["Mars", nil])
      end

      it "should exclude properties given to :exclude option" do
        planet = Planet.new(
          :name     => "Mars",
          :aphelion => 249_209_300.4
        )

        result = @harness.test(planet, :exclude => [:aphelion])
        expect(result.values_at("name", "aphelion")).to eq(["Mars", nil])
      end

      it "should give higher precendence to :only option over :exclude" do
        planet = Planet.new(
          :name     => "Mars",
          :aphelion => 249_209_300.4
        )

        result = @harness.test(planet, :only => [:name], :exclude => [:name])
        expect(result.values_at("name", "aphelion")).to eq(["Mars", nil])
      end

      it 'should support child associations included via the :methods parameter' do
        solar_system = SolarSystem.create(:name => "one")
        planet = Planet.new(:name => "earth")
        planet.solar_system = solar_system
        result = @harness.test(planet, :methods => [:solar_system])
        expect(result['solar_system'].values_at('name', 'id')).to eq(['one', 1])
      end
    end
  end

  describe "(collections and proxies)" do
    it 'should serialize Model.all' do
      # At the moment this is implied by serializing a collection, but this
      # test ensures the contract even if dm-core changes
      Cow.create(
        :id        => 89,
        :composite => 34,
        :name      => 'Berta',
        :breed     => 'Guernsey'
      )
      result = @harness.test(Cow.all)
      expect(result[0].values_at("name", "breed")).to eq(["Berta", "Guernsey"])
    end

    it 'should serialize a collection' do
      query = DataMapper::Query.new(DataMapper::repository(:default), Cow)

      keys = %w[ id composite name breed ]

      resources = [
        Hash[ keys.zip([  1,  2, 'Betsy', 'Jersey'   ]) ],
        Hash[ keys.zip([ 10, 20, 'Berta', 'Guernsey' ]) ],
      ]

      collection = DataMapper::Collection.new(query, query.model.load(resources, query))

      result = @harness.test(collection)
      expect(result[0].values_at(*keys)).to eq(resources[0].values_at(*keys))
      expect(result[1].values_at(*keys)).to eq(resources[1].values_at(*keys))
    end

    it 'should serialize an empty collection' do
      query = DataMapper::Query.new(DataMapper::repository(:default), Cow)
      collection = DataMapper::Collection.new(query)

      result = @harness.test(collection)
      expect(result).to be_empty
    end

    it "serializes a one to many relationship" do
      parent = Cow.new(:id => 1, :composite => 322, :name => "Harry", :breed => "Angus")
      baby = Cow.new(:mother_cow => parent, :id => 2, :composite => 321, :name => "Felix", :breed => "Angus")

      parent.save
      baby.save

      result = @harness.test(parent.baby_cows)
      expect(result).to be_kind_of(Array)

      expect(result[0].values_at(*%w{id composite name breed})).to eq([2, 321, "Felix", "Angus"])
    end

    it "serializes a many to one relationship" do
      parent = Cow.new(:id => 1, :composite => 322, :name => "Harry", :breed => "Angus")
      baby = Cow.new(:mother_cow => parent, :id => 2, :composite => 321, :name => "Felix", :breed => "Angus")

      parent.save
      baby.save

      result = @harness.test(baby.mother_cow)
      expect(result).to be_kind_of(Hash)
      expect(result.values_at(*%w{id composite name breed})).to eq([1, 322, "Harry", "Angus"])
    end

    it "serializes a many to many relationship" do
      pending 'TODO: fix many to many in dm-core'
      p1 = Planet.create(:name => 'earth')
      p2 = Planet.create(:name => 'mars')

      FriendedPlanet.create(:planet => p1, :friend_planet => p2)

      result = @harness.test(p1.reload.friend_planets)
      expect(result).to be_kind_of(Array)

      expect(result[0]["name"]).to eq("mars")
    end
  end

  with_alternate_adapter do

    describe "(multiple repositories)" do
      before :each do
        [ :default, :alternate ].each do |repository_name|
          DataMapper.repository(repository_name) do
            QuanTum::Cat.auto_migrate!
            QuanTum::Cat.destroy!
          end
        end
      end

      it "should use the repsoitory for the model" do
        alternate_repo = DataMapper::Spec.spec_adapters[:alternate].name
        gerry = QuanTum::Cat.create(:name => "gerry")
        george = DataMapper.repository(alternate_repo){ QuanTum::Cat.create(:name => "george", :is_dead => false) }
        expect(@harness.test(gerry )['is_dead']).to be(nil)
        expect(@harness.test(george)['is_dead']).to be(false)
      end
    end

  end

  it 'should integrate with dm-validations' do
    planet = Planet.create(:name => 'a')
    results = @harness.test(planet.errors)
    expect(results).to eq({
      "name"            => planet.errors[:name].map { |e| e.to_s },
      "solar_system_id" => planet.errors[:solar_system_id].map { |e| e.to_s }
    })
  end
end
