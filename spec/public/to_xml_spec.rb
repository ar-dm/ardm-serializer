require 'spec_helper'
require 'rexml/document'

[:rexml, :libxml, :nokogiri].each do |lib|
  begin
    DataMapper::Serializer::XML.serializer = lib
  rescue LoadError => e
    warn "[WARNING] #{e.message}"
    warn "[WARNING] Not running #to_xml specs for #{lib}"
    next
  end

  describe DataMapper::Serializer, "#to_xml using #{lib}" do
    before(:all) do
      DataMapper.finalize

      @harness = Class.new(SerializerTestHarness) {
        def method_name
          :to_xml
        end

        protected

        def deserialize(result)
          f = lambda do |element|
            case element.attributes["type"]
            when "hash"
              element.elements.to_a.inject({}) do |a, e|
                a.update(e.name => f[e])
              end
            when "array"
              element.elements.collect do |e|
                f[e]
              end
            else
              if element.elements.empty?
                cast(element.text, element.attributes["type"])
              else
                element.elements.to_a.inject({}) do |a, e|
                  a.update(e.name => f[e])
                end
              end
            end
          end

          doc = REXML::Document.new(result)
          f[doc.elements[1]]
        end

        def cast(value, type)
          boolean_conversions = {"true" => true, "false" => false}
          value = boolean_conversions[value] if boolean_conversions.has_key?(value)
          value = value.to_i if value && ["integer", "datamapper::types::serial"].include?(type)
          value
        end
      }.new
    end

    include_examples "A serialization method"

    it "should not include the XML prologue, so that the result can be embedded in other XML documents" do
      planet = Planet.new
      xml = planet.to_xml(:element_name => "aplanet")
      expect(xml).not_to match(/\A<?xml/)
    end

    describe ':element_name option for Resource' do
      it 'should be used as the root node name by #to_xml' do
        planet = Planet.new
        xml = planet.to_xml(:element_name => "aplanet")
        expect(REXML::Document.new(xml).elements[1].name).to eq("aplanet")
      end

      it 'when not specified the class name underscored and with slashes replaced with dashes should be used as the root node name' do
        cat = QuanTum::Cat.new
        xml = cat.to_xml
        expect(REXML::Document.new(xml).elements[1].name).to eq("quan_tum-cat")
      end
    end

    describe ':collection_element_name for Collection' do
      before(:each) do
        @model = QuanTum::Cat
        @query = DataMapper::Query.new(DataMapper::repository(:default), @model)
        @collection = DataMapper::Collection.new(@query)
      end

      it 'when not specified the class name tableized and with slashes replaced with dashes should be used as the root node name' do
        xml = DataMapper::Collection.new(@query).to_xml
        expect(REXML::Document.new(xml).elements[1].name).to eq("quan_tum-cats")
      end

      it 'should be used as the root node name by #to_xml' do
        resources = @model.load([ { 'id' => 1 } ], @query)
        @collection = DataMapper::Collection.new(@query, resources)

        xml = @collection.to_xml(:collection_element_name => "somanycats")
        expect(REXML::Document.new(xml).elements[1].name).to eq("somanycats")
      end

      it 'should respect :element_name for collection elements' do
        resources = @model.load([ { 'id' => 1 } ], @query)
        @collection = DataMapper::Collection.new(@query, resources)

        xml = @collection.to_xml(:collection_element_name => "somanycats", :element_name => 'cat')
        expect(REXML::Document.new(xml).elements[1].elements[1].name).to eq("cat")
      end
    end
  end
end
