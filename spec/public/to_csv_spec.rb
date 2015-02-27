require 'spec_helper'

if defined?(::CSV)
  RSpec.describe DataMapper::Serialize, '#to_csv' do
    #
    # ==== blah, it's CSV
    #

    before :all do
      DataMapper.finalize
    end

    before :each do
      query = DataMapper::Query.new(DataMapper::repository(:default), Cow)

      resources = [
        {:id => 1, :composite => 2, :name => 'Betsy', :breed => 'Jersey'},
        {:id => 10, :composite => 20, :name => 'Berta', :breed => 'Guernsey'}
      ]

      @collection = DataMapper::Collection.new(query, resources)

      @empty_collection = DataMapper::Collection.new(query)
    end

    it "should serialize a resource to CSV" do
      peter = Cow.new
      peter.id = 44
      peter.composite = 344
      peter.name = 'Peter'
      peter.breed = 'Long Horn'

      expect(peter.to_csv.chomp.split(',')[0..3]).to eq(['44','344','Peter','Long Horn'])
    end

    it "should serialize a collection to CSV" do
      result = @collection.to_csv.gsub(/[[:space:]]+\n/, "\n")
      expect(result.split("\n")[0].split(',')[0..3]).to eq(['1','2','Betsy','Jersey'])
      expect(result.split("\n")[1].split(',')[0..3]).to eq(['10','20','Berta','Guernsey'])
    end

    it 'should integrate with dm-validations by providing one line per error' do
      planet = Planet.create(:name => 'a')
      result = planet.errors.to_csv.gsub(/[[:space:]]+\n/, "\n").split("\n")
      expect(result).to include("name,#{planet.errors[:name][0]}")
      expect(result).to include("solar_system_id,#{planet.errors[:solar_system_id][0]}")
      expect(result.length).to eq(2)
    end

    with_alternate_adapter do

      describe "multiple repositories" do
        before :all do
          [ :default, :alternate ].each do |repository_name|
            DataMapper.repository(repository_name) do
              DataMapper.finalize
              QuanTum::Cat.auto_migrate!
              QuanTum::Cat.destroy!
            end
          end
        end

        it "should use the repsoitory for the model" do
          gerry = QuanTum::Cat.create(:name => "gerry")
          george = DataMapper.repository(:alternate){ QuanTum::Cat.create(:name => "george", :is_dead => false) }
          expect(gerry.to_csv).not_to match(/false/)
          expect(george.to_csv).to match(/false/)
        end
      end

    end
  end
else
  warn "[WARNING] Cannot require 'faster_csv' or 'csv', not running #to_csv specs"
end
