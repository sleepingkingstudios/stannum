# frozen_string_literal: true

require 'bigdecimal'

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'stannum/entities/attributes'

require 'support/examples/entities'
require 'support/examples/entity_examples'

module Spec::Support::Examples::Entities
  module AssociationsExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    include Spec::Support::Examples::EntityExamples

    shared_context 'when the entity class defines associations' do
      let(:entity_class) do
        defined?(super()) ? super() : Spec::EntityClass
      end

      example_class 'Spec::Parent' do |klass|
        klass.include Stannum::Entity

        klass.define_attribute :name, String
      end
      example_class 'Spec::Sibling' do |klass|
        klass.include Stannum::Entity

        klass.define_attribute :name, String
      end
      example_class 'Spec::Child' do |klass|
        klass.include Stannum::Entity

        klass.define_attribute :name, String
      end

      before(:example) do
        entity_class.instance_eval do
          association :one,
            'parent',
            class_name: 'Spec::Parent',
            inverse:    false
          association :one,
            'sibling',
            class_name: 'Spec::Sibling',
            inverse:    false
          association :one,
            'child',
            class_name: 'Spec::Child',
            inverse:    false
        end
      end
    end

    shared_context 'when the entity class defines associations with ' \
                   'foreign keys' \
    do
      let(:entity_class) do
        defined?(super()) ? super() : Spec::EntityClass
      end

      before(:example) do
        unless entity_class < Stannum::Entities::Attributes
          entity_class.include Stannum::Entities::Attributes
        end
      end

      example_class 'Spec::Parent' do |klass|
        klass.include Stannum::Entity

        klass.define_attribute :name, String
      end

      before(:example) do
        entity_class.instance_eval do
          association :one,
            'parent',
            class_name:  'Spec::Parent',
            foreign_key: true,
            inverse:     false
        end
      end
    end

    shared_context 'when the subclass defines associations' do
      example_class 'Spec::Bestie', Struct.new(:name)

      before(:example) do
        entity_class.instance_eval do
          association :one, 'bestie', class_name: 'Spec::Bestie', inverse: false
        end
      end
    end

    shared_context 'when the subclass defines associations with foreign keys' do
      example_class 'Spec::Bestie', Struct.new(:name)

      before(:example) do
        unless entity_class < Stannum::Entities::Attributes
          entity_class.include Stannum::Entities::Attributes
        end

        entity_class.instance_eval do
          association :one,
            'bestie',
            class_name:  'Spec::Bestie',
            foreign_key: true,
            inverse:     false
        end
      end
    end

    shared_context 'when the entity has association values' do
      let(:associations) do
        {
          'parent'  => Spec::Parent.new(name: 'original parent'),
          'sibling' => Spec::Sibling.new(name: 'original sibling'),
          'child'   => Spec::Sibling.new(name: 'original child')
        }
      end
      let(:properties) do
        defined?(super()) ? super().merge(associations) : associations
      end
    end

    shared_examples 'should implement the Associations methods' do
      describe '::Associations' do
        it { expect(described_class).to define_constant(:Associations) }

        it { expect(described_class::Associations).to be_a Module }

        it 'should include the Associations schema' do
          expect(described_class.ancestors)
            .to include described_class::Associations
        end

        it { expect(described_class::Associations.keys).to be == [] }

        wrap_context 'when the entity class defines associations' do
          it 'should define associations for the entity class' do
            expect(described_class::Associations.keys)
              .to contain_exactly('parent', 'sibling', 'child')
          end
        end

        wrap_context 'with an abstract entity class' do
          it { expect(abstract_class::Associations.keys).to be == [] }

          it { expect(described_class::Associations.keys).to be == [] }

          wrap_context 'when the entity class defines associations' do
            it { expect(abstract_class::Associations.keys).to be == [] }

            it 'should define associations for the entity class' do
              expect(described_class::Associations.keys)
                .to contain_exactly('parent', 'sibling', 'child')
            end
          end
        end

        wrap_context 'with an abstract entity module' do
          it { expect(described_class::Associations.keys).to be == [] }

          wrap_context 'when the entity class defines associations' do
            it 'should define associations for the entity class' do
              expect(described_class::Associations.keys)
                .to contain_exactly('parent', 'sibling', 'child')
            end
          end
        end

        wrap_context 'with an entity subclass' do
          let(:associations) { described_class::Associations }

          it { expect(described_class).to define_constant(:Associations) }

          it { expect(associations).to be_a Stannum::Schema }

          it 'should generate independent associations for the subclass' do
            expect(associations).not_to be entity_superclass::Associations
          end

          wrap_context 'when the entity class defines associations' do
            it 'should define associations for the entity class' do
              expect(described_class::Associations.keys)
                .to contain_exactly('parent', 'sibling', 'child')
            end
          end

          wrap_context 'when the subclass defines associations' do
            it 'should define associations for the entity class' do
              expect(described_class::Associations.keys)
                .to contain_exactly('bestie')
            end
          end

          context 'when the struct and the subclass define associations' do
            include_context 'when the entity class defines associations'
            include_context 'when the subclass defines associations'

            it 'should define associations for the entity class' do
              expect(described_class::Associations.keys)
                .to contain_exactly('parent', 'sibling', 'child', 'bestie')
            end
          end
        end
      end

      describe '.association' do
        shared_context 'with an entity class with attributes' do
          before(:example) do
            unless entity_class < Stannum::Entities::Attributes
              entity_class.include Stannum::Entities::Attributes
            end
          end
        end

        shared_examples 'should define a foreign key attribute' \
        do |**example_options|
          let(:foreign_key_name) do
            example_options.fetch(:foreign_key_name) do
              "#{assoc_name}_id"
            end
          end
          let(:foreign_key_type) do
            example_options.fetch(:foreign_key_type) do
              described_class.default_foreign_key_type
            end
          end
          let(:attribute_options) do
            {
              association_name: assoc_name.to_s,
              foreign_key:      true,
              required:         false
            }
          end

          it 'should add the attribute to ::Attributes' do
            expect { define_association }
              .to change { described_class.attributes.count }
              .by(1)
          end

          it 'should add the attribute key to ::Attributes' do
            expect { define_association }
              .to change(described_class.attributes, :each_key)
              .to include(foreign_key_name.to_s)
          end

          it 'should add the attribute value to ::Attributes',
            :aggregate_failures \
          do
            define_association

            attribute = described_class.attributes[foreign_key_name]

            expect(attribute).to be_a Stannum::Attribute
            expect(attribute.name).to be == foreign_key_name
            expect(attribute.type).to be == foreign_key_type.to_s
            expect(attribute.options).to deep_match(attribute_options)
          end
        end

        shared_examples 'should define a singular association' \
        do |**example_options|
          let(:foreign_key_options) do
            next {} unless example_options[:foreign_key]

            name = example_options.fetch(:foreign_key_name) do
              "#{assoc_name}_id"
            end
            type = example_options.fetch(:foreign_key_type) do
              described_class.default_foreign_key_type
            end

            {
              foreign_key_name: name,
              foreign_key_type: type
            }
          end
          let(:inverse_options) do
            next { inverse: false } if example_options[:inverse] == false

            hsh = {
              entity_class_name: entity_class.name,
              inverse:           true
            }

            next hsh unless example_options[:inverse_name]

            hsh.merge(inverse_name: example_options[:inverse_name])
          end
          let(:expected_options) do
            options
              .dup
              .tap { |hsh| hsh.delete(:class_name) }
              .tap { |hsh| hsh.delete(:foreign_key) }
              .tap { |hsh| hsh.delete(:inverse) }
              .merge(foreign_key_options)
              .merge(inverse_options)
          end

          it 'should add the association to ::Associations' do
            expect { define_association }
              .to change { described_class.associations.count }
              .by(1)
          end

          it 'should add the association key to ::Associations' do
            expect { define_association }
              .to change(described_class.associations, :each_key)
              .to include(assoc_name.to_s)
          end

          it 'should add the association value to ::Associations',
            :aggregate_failures \
          do
            define_association

            association = described_class.associations[assoc_name.to_s]

            expect(association).to be_a Stannum::Associations::One
            expect(association.name).to be == assoc_name.to_s
            expect(association.type).to be == assoc_type.to_s
            expect(association.options).to deep_match(expected_options)
          end
        end

        let(:assoc_name) { :reference }
        let(:assoc_type) { Reference }
        let(:key)        { assoc_name }
        let(:options)    { {} }

        example_class 'Reference' unless defined?(Reference)

        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:association)
            .with(2).arguments
            .and_any_keywords
        end

        describe 'with arity: :one' do
          let(:arity) { :one }

          def define_association
            described_class.association(:one, key, **options)
          end

          describe 'with an association class' do
            let(:key) { assoc_type }

            it 'should return the association name as a Symbol' do
              expect(described_class.association(arity, key, **options))
                .to be :reference
            end

            include_examples 'should define a singular association'

            describe 'with options: { class_name: value }' do
              let(:class_name) { 'Spec::OtherReference' }
              let(:options)    { super().merge(class_name: class_name) }
              let(:error_message) do
                'ambiguous class name "Reference" or "Spec::OtherReference" ' \
                  '- do not provide both a class and a :class_name keyword'
              end

              it 'should raise an exception' do
                expect { described_class.association(:one, key, **options) }
                  .to raise_error ArgumentError, error_message
              end
            end

            describe 'with a scoped class' do
              let(:assoc_name) { :custom_reference }
              let(:assoc_type) { Spec::CustomReference }

              example_class 'Spec::CustomReference'

              it 'should return the association name as a Symbol' do
                expect(described_class.association(arity, key, **options))
                  .to be :custom_reference
              end

              include_examples 'should define a singular association'

              describe 'with options: { class_name: value }' do
                let(:class_name) { 'Spec::OtherReference' }
                let(:options)    { super().merge(class_name: class_name) }
                let(:error_message) do
                  'ambiguous class name "Spec::CustomReference" or ' \
                    '"Spec::OtherReference" - do not provide both a class ' \
                    'and a :class_name keyword'
                end

                it 'should raise an exception' do
                  expect { described_class.association(:one, key, **options) }
                    .to raise_error ArgumentError, error_message
                end
              end
            end
          end

          describe 'with an association class name' do
            let(:key) { assoc_type.to_s }

            it 'should return the association name as a Symbol' do
              expect(described_class.association(arity, key, **options))
                .to be :reference
            end

            include_examples 'should define a singular association'

            describe 'with options: { class_name: value }' do
              let(:key)        { 'Reference' }
              let(:assoc_type) { Spec::OtherReference }
              let(:class_name) { 'Spec::OtherReference' }
              let(:options)    { super().merge(class_name: class_name) }

              example_class 'Spec::OtherReference'

              it 'should return the association name as a Symbol' do
                expect(described_class.association(arity, key, **options))
                  .to be :reference
              end

              include_examples 'should define a singular association'
            end

            describe 'with a scoped class' do
              let(:assoc_name) { :custom_reference }
              let(:assoc_type) { Spec::CustomReference }

              example_class 'Spec::CustomReference'

              it 'should return the association name as a Symbol' do
                expect(described_class.association(arity, key, **options))
                  .to be :custom_reference
              end

              include_examples 'should define a singular association'

              describe 'with options: { class_name: value }' do
                let(:class_name) { 'Spec::OtherReference' }
                let(:options)    { super().merge(class_name: class_name) }
                let(:error_message) do
                  'ambiguous class name "Spec::CustomReference" or ' \
                    '"Spec::OtherReference" - do not provide both a class ' \
                    'and a :class_name keyword'
                end

                it 'should raise an exception' do
                  expect { described_class.association(:one, key, **options) }
                    .to raise_error ArgumentError, error_message
                end
              end
            end
          end

          describe 'with an association name as a String' do
            let(:assoc_name) { 'reference' }

            it 'should return the association name as a Symbol' do
              expect(described_class.association(arity, key, **options))
                .to be :reference
            end

            include_examples 'should define a singular association'
          end

          describe 'with an association name as a Symbol' do
            let(:assoc_name) { :reference }

            it 'should return the association name as a Symbol' do
              expect(described_class.association(arity, key, **options))
                .to be :reference
            end

            include_examples 'should define a singular association'
          end

          describe 'with options: { class_name: a Class }' do
            let(:assoc_type) { Spec::OtherReference }
            let(:options)    { super().merge(class_name: assoc_type) }

            example_class 'Spec::OtherReference'

            it 'should return the association name as a Symbol' do
              expect(described_class.association(arity, key, **options))
                .to be :reference
            end

            include_examples 'should define a singular association'
          end

          describe 'with options: { class_name: a String }' do
            let(:assoc_type) { 'Spec::OtherReference' }
            let(:options)    { super().merge(class_name: assoc_type) }

            example_class 'Spec::OtherReference'

            it 'should return the association name as a Symbol' do
              expect(described_class.association(arity, key, **options))
                .to be :reference
            end

            include_examples 'should define a singular association'
          end

          describe 'with options: { foreign_key: false }' do
            let(:options) { { foreign_key: false } }

            include_examples 'should define a singular association'
          end

          describe 'with options: { foreign_key: true }' do
            include_context 'with an entity class with attributes'

            let(:options) { { foreign_key: true } }

            include_examples 'should define a foreign key attribute'

            include_examples 'should define a singular association',
              foreign_key: true

            context 'when the entity class defines a primary key' do
              before(:example) do
                unless entity_class < Stannum::Entities::PrimaryKey
                  entity_class.include Stannum::Entities::PrimaryKey
                end

                entity_class.define_primary_key(:uuid, String)
              end

              include_examples 'should define a foreign key attribute',
                foreign_key_type: String

              include_examples 'should define a singular association',
                foreign_key:      true,
                foreign_key_type: String
            end
          end

          describe 'with options: { foreign_key: an object }' do
            include_context 'with an entity class with attributes'

            let(:options) { { foreign_key: Object.new.freeze } }
            let(:error_message) do
              "invalid foreign key #{options[:foreign_key].inspect}"
            end

            it 'should raise an exception' do
              expect { define_association }.to raise_error(
                described_class::InvalidOptionError,
                error_message
              )
            end
          end

          describe 'with options: { foreign_key: a string }' do
            include_context 'with an entity class with attributes'

            let(:options) { { foreign_key: 'reference_fk' } }

            include_examples 'should define a foreign key attribute',
              foreign_key_name: 'reference_fk'

            include_examples 'should define a singular association',
              foreign_key:      true,
              foreign_key_name: 'reference_fk'

            context 'when the entity class defines a primary key' do
              before(:example) do
                unless entity_class < Stannum::Entities::PrimaryKey
                  entity_class.include Stannum::Entities::PrimaryKey
                end

                entity_class.define_primary_key(:uuid, String)
              end

              include_examples 'should define a foreign key attribute',
                foreign_key_name: 'reference_fk',
                foreign_key_type: String

              include_examples 'should define a singular association',
                foreign_key:      true,
                foreign_key_name: 'reference_fk',
                foreign_key_type: String
            end
          end

          describe 'with options: { foreign_key: a symbol }' do
            include_context 'with an entity class with attributes'

            let(:options) { { foreign_key: :reference_fk } }

            include_examples 'should define a foreign key attribute',
              foreign_key_name: 'reference_fk'

            include_examples 'should define a singular association',
              foreign_key:      true,
              foreign_key_name: 'reference_fk'

            context 'when the entity class defines a primary key' do
              before(:example) do
                unless entity_class < Stannum::Entities::PrimaryKey
                  entity_class.include Stannum::Entities::PrimaryKey
                end

                entity_class.define_primary_key(:uuid, String)
              end

              include_examples 'should define a foreign key attribute',
                foreign_key_name: 'reference_fk',
                foreign_key_type: String

              include_examples 'should define a singular association',
                foreign_key:      true,
                foreign_key_name: 'reference_fk',
                foreign_key_type: String
            end
          end

          describe 'with options: { foreign_key: a hash }' do
            include_context 'with an entity class with attributes'

            let(:options) { { foreign_key: {} } }

            include_examples 'should define a foreign key attribute'

            include_examples 'should define a singular association',
              foreign_key: true

            context 'when the entity class defines a primary key' do
              before(:example) do
                unless entity_class < Stannum::Entities::PrimaryKey
                  entity_class.include Stannum::Entities::PrimaryKey
                end

                entity_class.define_primary_key(:uuid, String)
              end

              include_examples 'should define a foreign key attribute',
                foreign_key_type: String

              include_examples 'should define a singular association',
                foreign_key:      true,
                foreign_key_type: String
            end

            describe 'with name: value' do
              let(:options) { { foreign_key: { name: 'reference_fk' } } }

              include_examples 'should define a foreign key attribute',
                foreign_key_name: 'reference_fk'

              include_examples 'should define a singular association',
                foreign_key:      true,
                foreign_key_name: 'reference_fk'

              context 'when the entity class defines a primary key' do
                before(:example) do
                  unless entity_class < Stannum::Entities::PrimaryKey
                    entity_class.include Stannum::Entities::PrimaryKey
                  end

                  entity_class.define_primary_key(:uuid, String)
                end

                include_examples 'should define a foreign key attribute',
                  foreign_key_name: 'reference_fk',
                  foreign_key_type: String

                include_examples 'should define a singular association',
                  foreign_key:      true,
                  foreign_key_name: 'reference_fk',
                  foreign_key_type: String
              end
            end

            describe 'with type: value' do
              let(:options) { { foreign_key: { type: String } } }

              include_examples 'should define a foreign key attribute',
                foreign_key_type: String

              include_examples 'should define a singular association',
                foreign_key:      true,
                foreign_key_type: String
            end

            describe 'with name: value and type: value' do
              let(:options) do
                { foreign_key: { name: 'reference_fk', type: String } }
              end

              include_examples 'should define a foreign key attribute',
                foreign_key_name: 'reference_fk',
                foreign_key_type: String

              include_examples 'should define a singular association',
                foreign_key:      true,
                foreign_key_name: 'reference_fk',
                foreign_key_type: String
            end
          end

          describe 'with options: { inverse: false }' do
            let(:options) { super().merge(inverse: false) }

            include_examples 'should define a singular association',
              inverse: false
          end

          describe 'with options: { inverse: true }' do
            let(:options) { super().merge(inverse: true) }

            include_examples 'should define a singular association'
          end

          describe 'with options: { inverse: a String }' do
            let(:options) { super().merge(inverse: 'widget') }

            include_examples 'should define a singular association',
              inverse_name: 'widget'
          end

          describe 'with options: { inverse: a Symbol }' do
            let(:options) { super().merge(inverse: :widget) }

            include_examples 'should define a singular association',
              inverse_name: 'widget'
          end

          describe 'with options: custom value' do
            let(:options) { { key: 'value' } }

            include_examples 'should define a singular association'
          end
        end

        describe 'with arity: other value' do
          let(:arity)         { :none }
          let(:error_message) { 'association arity must be :one' }

          it 'should raise an exception' do
            expect { described_class.association(arity, key, **options) }
              .to raise_error ArgumentError, error_message
          end
        end

        wrap_context 'when the entity class defines associations' do
          describe 'with arity: :one' do
            let(:arity) { :one }

            def define_association
              described_class.association(:one, key, **options)
            end

            include_examples 'should define a singular association'

            describe 'with options: value' do
              let(:options) { { key: 'value' } }

              include_examples 'should define a singular association'
            end
          end
        end
      end

      describe '.associations' do
        it { expect(described_class).to have_reader(:associations) }

        it { expect(described_class.associations).to be_a Module }

        it { expect(described_class.associations.keys).to be == [] }

        wrap_context 'when the entity class defines associations' do
          it 'should define associations for the entity class' do
            expect(described_class.associations.keys)
              .to contain_exactly('parent', 'sibling', 'child')
          end
        end

        wrap_context 'with an abstract entity class' do
          it { expect(abstract_class.associations.keys).to be == [] }

          it { expect(described_class.associations.keys).to be == [] }

          wrap_context 'when the entity class defines associations' do
            it { expect(abstract_class.associations.keys).to be == [] }

            it 'should define associations for the entity class' do
              expect(described_class.associations.keys)
                .to contain_exactly('parent', 'sibling', 'child')
            end
          end
        end

        wrap_context 'with an abstract entity module' do
          it { expect(described_class.associations.keys).to be == [] }

          wrap_context 'when the entity class defines associations' do
            it 'should define associations for the entity class' do
              expect(described_class.associations.keys)
                .to contain_exactly('parent', 'sibling', 'child')
            end
          end
        end

        wrap_context 'with an entity subclass' do
          let(:associations) { described_class.associations }

          it { expect(described_class).to have_reader(:associations) }

          it { expect(associations).to be_a Stannum::Schema }

          it 'should generate independent associations for the subclass' do
            expect(associations).not_to be entity_superclass.associations
          end

          wrap_context 'when the entity class defines associations' do
            it 'should define associations for the entity class' do
              expect(described_class.associations.keys)
                .to contain_exactly('parent', 'sibling', 'child')
            end
          end

          wrap_context 'when the subclass defines associations' do
            it 'should define associations for the entity class' do
              expect(described_class.associations.keys)
                .to contain_exactly('bestie')
            end
          end

          context 'when the struct and the subclass define associations' do
            include_context 'when the entity class defines associations'
            include_context 'when the subclass defines associations'

            it 'should define associations for the entity class' do
              expect(described_class.associations.keys)
                .to contain_exactly('parent', 'sibling', 'child', 'bestie')
            end
          end
        end
      end

      describe '.default_foreign_key_type' do
        include_examples 'should define class reader',
          :default_foreign_key_type,
          Integer

        context 'when the entity class defines a primary key' do
          before(:example) do
            unless entity_class < Stannum::Entities::Attributes
              entity_class.include Stannum::Entities::Attributes
            end

            unless entity_class < Stannum::Entities::PrimaryKey
              entity_class.include Stannum::Entities::PrimaryKey
            end

            entity_class.define_primary_key(:uuid, String)
          end

          it 'should default to the primary key type' do
            expect(described_class.default_foreign_key_type)
              .to be == described_class.primary_key_type
          end
        end
      end

      describe '.new' do
        wrap_context 'when the entity class defines associations' do
          describe 'with no parameters' do
            let(:expected) do
              {
                'parent'  => nil,
                'sibling' => nil,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it 'should set the associations' do
              expect(described_class.new(**properties).associations)
                .to be == expected
            end

            it 'should set the properties' do
              expect(described_class.new(**properties).properties)
                .to be == expected
            end
          end

          describe 'with invalid String keys' do
            let(:properties)    { super().merge('upc' => '12345') }
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with invalid Symbol keys' do
            let(:properties)    { super().merge(upc: '12345') }
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:properties) do
              {
                'parent' => Spec::Parent.new,
                'upc'    => '12345'
              }
            end
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:properties) do
              {
                parent: Spec::Parent.new,
                upc:    '12345'
              }
            end
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with valid String keys' do
            let(:parent)  { Spec::Parent.new }
            let(:sibling) { Spec::Sibling.new }
            let(:properties) do
              {
                'parent'  => parent,
                'sibling' => sibling
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it 'should set the associations' do
              expect(described_class.new(**properties).associations)
                .to be == expected
            end

            it 'should set the properties' do
              expect(described_class.new(**properties).properties)
                .to be == expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent)  { Spec::Parent.new }
            let(:sibling) { Spec::Sibling.new }
            let(:properties) do
              {
                parent:  parent,
                sibling: sibling
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it 'should set the associations' do
              expect(described_class.new(**properties).associations)
                .to be == expected
            end

            it 'should set the properties' do
              expect(described_class.new(**properties).properties)
                .to be == expected
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          describe 'with valid String keys' do
            let(:parent)  { Spec::Parent.new }
            let(:sibling) { Spec::Sibling.new }
            let(:properties) do
              {
                'amplitude' => '1 TW',
                'frequency' => '1 Hz',
                'parent'    => parent,
                'sibling'   => sibling
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              )
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it 'should set the associations' do
              expect(described_class.new(**properties).associations)
                .to be == expected_associations
            end

            it 'should set the properties' do
              expect(described_class.new(**properties).properties)
                .to be == expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent)  { Spec::Parent.new }
            let(:sibling) { Spec::Sibling.new }
            let(:properties) do
              {
                amplitude: '1 TW',
                frequency: '1 Hz',
                parent:    parent,
                sibling:   sibling
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              )
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it 'should set the associations' do
              expect(described_class.new(**properties).associations)
                .to be == expected_associations
            end

            it 'should set the properties' do
              expect(described_class.new(**properties).properties)
                .to be == expected_properties
            end
          end
        end
      end

      describe '#==' do
        wrap_context 'when the entity class defines associations' do
          describe 'with an entity with matching associations' do
            let(:other) { described_class.new(**properties) }

            it { expect(entity == other).to be true }
          end

          describe 'with an entity with non-matching associations' do
            let(:other_properties) do
              properties.merge(parent: Spec::Parent.new)
            end
            let(:other) { described_class.new(**other_properties) }

            it { expect(entity == other).to be false }
          end

          wrap_context 'when the entity has association values' do
            describe 'with an entity with matching associations' do
              let(:other) { described_class.new(**properties) }

              it { expect(entity == other).to be true }
            end

            describe 'with an entity with non-matching associations' do
              let(:other_properties) do
                properties.merge(parent: Spec::Parent.new(name: 'other parent'))
              end
              let(:other) { described_class.new(**other_properties) }

              it { expect(entity == other).to be false }
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          describe 'with an entity with matching properties' do
            let(:other) { described_class.new(**properties) }

            it { expect(entity == other).to be true }
          end

          describe 'with an entity with non-matching properties' do
            let(:other_properties) do
              properties.merge(
                amplitude: '1.21 GW',
                parent:    Spec::Parent.new(name: 'other parent')
              )
            end
            let(:other) { described_class.new(**other_properties) }

            it { expect(entity == other).to be false }
          end

          context 'when the entity has association values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            describe 'with an entity with matching properties' do
              let(:other) { described_class.new(**properties) }

              it { expect(entity == other).to be true }
            end

            describe 'with an entity with non-matching properties' do
              let(:other_properties) do
                properties.merge(
                  amplitude: '1.21 GW',
                  parent:    Spec::Parent.new(name: 'other parent')
                )
              end
              let(:other) { described_class.new(**other_properties) }

              it { expect(entity == other).to be false }
            end
          end
        end
      end

      describe '#:association' do
        it { expect(entity).not_to respond_to(:bestie) }

        it { expect(entity).not_to respond_to(:parent) }

        wrap_context 'when the entity class defines associations' do
          it { expect(entity).not_to respond_to(:bestie) }

          it { expect(entity).to respond_to(:parent).with(0).arguments }
        end

        wrap_context 'with an entity subclass' do
          it { expect(entity).not_to respond_to(:bestie) }

          it { expect(entity).not_to respond_to(:parent) }

          wrap_context 'when the entity class defines associations' do
            it { expect(entity).not_to respond_to(:bestie) }

            it { expect(entity).to respond_to(:parent).with(0).arguments }
          end

          wrap_context 'when the subclass defines associations' do
            it { expect(entity).to respond_to(:bestie).with(0).arguments }

            it { expect(entity).not_to respond_to(:parent) }
          end

          context 'when the struct and the subclass define associations' do
            include_context 'when the entity class defines associations'
            include_context 'when the subclass defines associations'

            it { expect(entity).to respond_to(:bestie).with(0).arguments }

            it { expect(entity).to respond_to(:parent).with(0).arguments }
          end
        end
      end

      describe '#:association=' do
        it { expect(entity).not_to respond_to(:bestie=) }

        it { expect(entity).not_to respond_to(:parent=) }

        wrap_context 'when the entity class defines associations' do
          it { expect(entity).not_to respond_to(:bestie=) }

          it { expect(entity).to respond_to(:parent=).with(1).argument }
        end

        wrap_context 'with an entity subclass' do
          it { expect(entity).not_to respond_to(:bestie=) }

          it { expect(entity).not_to respond_to(:parent=) }

          wrap_context 'when the entity class defines associations' do
            it { expect(entity).not_to respond_to(:bestie=) }

            it { expect(entity).to respond_to(:parent=).with(1).argument }
          end

          wrap_context 'when the subclass defines associations' do
            it { expect(entity).to respond_to(:bestie=).with(1).argument }

            it { expect(entity).not_to respond_to(:parent=) }
          end

          context 'when the struct and the subclass define associations' do
            include_context 'when the entity class defines associations'
            include_context 'when the subclass defines associations'

            it { expect(entity).to respond_to(:parent=).with(1).argument }

            it { expect(entity).to respond_to(:bestie=).with(1).argument }
          end
        end
      end

      describe '#:foreign_key' do
        it { expect(entity).not_to respond_to(:bestie_id) }

        it { expect(entity).not_to respond_to(:parent_id) }

        # rubocop:disable RSpec/RepeatedExampleGroupBody
        wrap_context 'when the entity class defines associations' do
          it { expect(entity).not_to respond_to(:bestie_id) }

          it { expect(entity).not_to respond_to(:parent_id) }
        end

        wrap_context 'when the entity class defines associations with ' \
                     'foreign keys' \
        do
          it { expect(entity).not_to respond_to(:bestie_id) }

          it { expect(entity).to respond_to(:parent_id).with(0).arguments }
        end

        wrap_context 'when the subclass defines associations' do
          it { expect(entity).not_to respond_to(:bestie_id) }

          it { expect(entity).not_to respond_to(:parent_id) }
        end

        wrap_context 'when the subclass defines associations with foreign ' \
                     'keys' \
        do
          it { expect(entity).to respond_to(:bestie_id).with(0).arguments }

          it { expect(entity).not_to respond_to(:parent_id) }
        end

        context 'when the struct and the subclass define associations' do
          include_context 'when the entity class defines associations with ' \
                          'foreign keys'
          include_context 'when the subclass defines associations with ' \
                          'foreign keys'

          it { expect(entity).to respond_to(:bestie_id).with(0).arguments }

          it { expect(entity).to respond_to(:parent_id).with(0).arguments }
        end
        # rubocop:enable RSpec/RepeatedExampleGroupBody
      end

      describe '#:foreign_key=' do
        it { expect(entity).not_to respond_to(:bestie_id=) }

        it { expect(entity).not_to respond_to(:parent_id=) }

        # rubocop:disable RSpec/RepeatedExampleGroupBody
        wrap_context 'when the entity class defines associations' do
          it { expect(entity).not_to respond_to(:bestie_id=) }

          it { expect(entity).not_to respond_to(:parent_id=) }
        end

        wrap_context 'when the entity class defines associations with ' \
                     'foreign keys' \
        do
          it { expect(entity).not_to respond_to(:bestie_id=) }

          it { expect(entity).to respond_to(:parent_id=).with(1).argument }
        end

        wrap_context 'when the subclass defines associations' do
          it { expect(entity).not_to respond_to(:bestie_id=) }

          it { expect(entity).not_to respond_to(:parent_id=) }
        end

        wrap_context 'when the subclass defines associations with foreign ' \
                     'keys' \
        do
          it { expect(entity).to respond_to(:bestie_id=).with(1).argument }

          it { expect(entity).not_to respond_to(:parent_id=) }
        end

        context 'when the struct and the subclass define associations' do
          include_context 'when the entity class defines associations with ' \
                          'foreign keys'
          include_context 'when the subclass defines associations with ' \
                          'foreign keys'

          it { expect(entity).to respond_to(:bestie_id=).with(1).argument }

          it { expect(entity).to respond_to(:parent_id=).with(1).argument }
        end
        # rubocop:enable RSpec/RepeatedExampleGroupBody
      end

      describe '#[]' do
        wrap_context 'when the entity class defines associations' do
          describe 'with an invalid String' do
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity['phase_angle'] }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with an invalid Symbol' do
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity[:phase_angle] }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with a valid String' do
            it { expect(entity['parent']).to be nil }
          end

          describe 'with a valid Symbol' do
            it { expect(entity[:parent]).to be nil }
          end

          wrap_context 'when the entity has association values' do
            describe 'with a valid String' do
              it { expect(entity['parent']).to be == associations['parent'] }
            end

            describe 'with a valid Symbol' do
              it { expect(entity[:parent]).to be == associations['parent'] }
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          describe 'with an invalid String' do
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity['phase_angle'] }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with an invalid Symbol' do
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity[:phase_angle] }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with a valid association String' do
            it { expect(entity['parent']).to be nil }
          end

          describe 'with a valid association Symbol' do
            it { expect(entity[:parent]).to be nil }
          end

          describe 'with a valid property String' do
            it { expect(entity['amplitude']).to be nil }
          end

          describe 'with a valid property Symbol' do
            it { expect(entity[:amplitude]).to be nil }
          end

          context 'when the entity has association values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            describe 'with a valid association String' do
              it { expect(entity['parent']).to be == associations['parent'] }
            end

            describe 'with a valid association Symbol' do
              it { expect(entity[:parent]).to be == associations['parent'] }
            end

            describe 'with a valid property String' do
              it 'should return the property value' do
                expect(entity['amplitude'])
                  .to be == generic_properties['amplitude']
              end
            end

            describe 'with a valid property Symbol' do
              it 'should return the property value' do
                expect(entity[:amplitude])
                  .to be == generic_properties['amplitude']
              end
            end
          end
        end
      end

      describe '#[]=' do
        wrap_context 'when the entity class defines associations' do
          describe 'with an invalid String' do
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity['phase_angle'] = 'π' }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with an invalid Symbol' do
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity[:phase_angle] = 'π' }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with a valid String' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }

            it 'should call the writer method' do
              allow(entity).to receive(:parent=)

              entity['parent'] = parent

              expect(entity)
                .to have_received(:parent=)
                .with(parent)
            end

            it 'should change the property value' do
              expect { entity['parent'] = parent }
                .to change { entity['parent'] }
                .to be parent
            end
          end

          describe 'with a valid Symbol' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }

            it 'should call the writer method' do
              allow(entity).to receive(:parent=)

              entity[:parent] = parent

              expect(entity)
                .to have_received(:parent=)
                .with(parent)
            end

            it 'should change the property value' do
              expect { entity[:parent] = parent }
                .to change { entity['parent'] }
                .to be parent
            end
          end

          wrap_context 'when the entity has association values' do
            describe 'with a valid String' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }

              it 'should change the property value' do
                expect { entity['parent'] = parent }
                  .to change { entity['parent'] }
                  .to be == parent
              end
            end

            describe 'with a valid Symbol' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }

              it 'should change the property value' do
                expect { entity[:parent] = parent }
                  .to change { entity['parent'] }
                  .to be == parent
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          describe 'with an invalid String' do
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity['phase_angle'] = 'π' }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with an invalid Symbol' do
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity[:phase_angle] = 'π' }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with a valid association String' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }

            it 'should call the writer method' do
              allow(entity).to receive(:parent=)

              entity['parent'] = parent

              expect(entity)
                .to have_received(:parent=)
                .with(parent)
            end

            it 'should change the property value' do
              expect { entity['parent'] = parent }
                .to change { entity['parent'] }
                .to be parent
            end
          end

          describe 'with a valid association Symbol' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }

            it 'should call the writer method' do
              allow(entity).to receive(:parent=)

              entity[:parent] = parent

              expect(entity)
                .to have_received(:parent=)
                .with(parent)
            end

            it 'should change the property value' do
              expect { entity[:parent] = parent }
                .to change { entity['parent'] }
                .to be parent
            end
          end

          describe 'with a valid property String' do
            it 'should change the property value' do
              expect { entity['amplitude'] = '1.21 GW' }
                .to change { entity['amplitude'] }
                .to be == '1.21 GW'
            end
          end

          describe 'with a valid property Symbol' do
            it 'should change the property value' do
              expect { entity[:amplitude] = '1.21 GW' }
                .to change { entity['amplitude'] }
                .to be == '1.21 GW'
            end
          end

          context 'when the entity has association values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            describe 'with a valid association String' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }

              it 'should change the property value' do
                expect { entity['parent'] = parent }
                  .to change { entity['parent'] }
                  .to be parent
              end
            end

            describe 'with a valid association Symbol' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }

              it 'should change the property value' do
                expect { entity[:parent] = parent }
                  .to change { entity['parent'] }
                  .to be parent
              end
            end

            describe 'with a valid property String' do
              it 'should change the property value' do
                expect { entity['amplitude'] = '1.21 GW' }
                  .to change { entity['amplitude'] }
                  .to be == '1.21 GW'
              end
            end

            describe 'with a valid property Symbol' do
              it 'should change the property value' do
                expect { entity[:amplitude] = '1.21 GW' }
                  .to change { entity['amplitude'] }
                  .to be == '1.21 GW'
              end
            end
          end
        end
      end

      describe '#assign_associations' do
        def rescue_exception
          yield
        rescue ArgumentError
          # Do nothing.
        end

        it 'should define the method' do
          expect(entity).to respond_to(:assign_associations).with(1).argument
        end

        describe 'with nil' do
          let(:error_message) { 'associations must be a Hash' }

          it 'should raise an exception' do
            expect { entity.assign_associations nil }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) { 'associations must be a Hash' }

          it 'should raise an exception' do
            expect { entity.assign_associations Object.new.freeze }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with nil keys' do
          let(:values)        { { nil => 'value' } }
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.assign_associations(values) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with Object keys' do
          let(:values)        { { Object.new.freeze => 'value' } }
          let(:error_message) { 'association is not a String or a Symbol' }

          it 'should raise an exception' do
            expect { entity.assign_associations(values) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with empty String keys' do
          let(:values)        { { '' => 'value' } }
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.assign_associations(values) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with empty Symbol keys' do
          let(:values)        { { '': 'value' } }
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.assign_associations(values) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with empty associations' do
          let(:values) { {} }

          it 'should not raise an exception' do
            expect { entity.assign_associations(values) }.not_to raise_error
          end

          it 'should not change the entity associations' do
            expect { entity.assign_associations(values) }
              .not_to change(entity, :associations)
          end

          it 'should not change the entity properties' do
            expect { entity.assign_associations(values) }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid String keys' do
          let(:values)        { { 'phase_angle' => 'π' } }
          let(:error_message) { 'unknown association "phase_angle"' }

          it 'should raise an exception' do
            expect { entity.assign_associations(values) }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the entity associations' do
            expect { rescue_exception { entity.assign_associations(values) } }
              .not_to change(entity, :associations)
          end

          it 'should not change the entity properties' do
            expect { rescue_exception { entity.assign_associations(values) } }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid Symbol keys' do
          let(:values)        { { phase_angle: 'π' } }
          let(:error_message) { 'unknown association :phase_angle' }

          it 'should raise an exception' do
            expect { entity.assign_associations(values) }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the entity associations' do
            expect { rescue_exception { entity.assign_associations(values) } }
              .not_to change(entity, :associations)
          end

          it 'should not change the entity properties' do
            expect { rescue_exception { entity.assign_associations(values) } }
              .not_to change(entity, :properties)
          end
        end

        wrap_context 'when the entity class defines associations' do
          describe 'with empty associations' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.assign_associations(values) }.not_to raise_error
            end

            it 'should not change the entity associations' do
              expect { entity.assign_associations(values) }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { entity.assign_associations(values) }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown association "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_associations(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown association :upc' }

            it 'should raise an exception' do
              expect { entity.assign_associations(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'parent' => Spec::Parent.new(name: 'new parent'),
                'upc'    => '12345'
              }
            end
            let(:error_message) { 'unknown association "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_associations(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                parent: Spec::Parent.new(name: 'new parent'),
                upc:    '12345'
              }
            end
            let(:error_message) { 'unknown association :upc' }

            it 'should raise an exception' do
              expect { entity.assign_associations(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:parent)  { Spec::Parent.new }
            let(:sibling) { Spec::Sibling.new }
            let(:values) do
              {
                'parent'  => parent,
                'sibling' => sibling
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_associations(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.assign_associations(values)

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(sibling)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .to change(entity, :associations)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent)  { Spec::Parent.new }
            let(:sibling) { Spec::Sibling.new }
            let(:values) do
              {
                parent:  parent,
                sibling: sibling
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_associations(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.assign_associations(values)

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(sibling)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .to change(entity, :associations)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          wrap_context 'when the entity has association values' do
            describe 'with empty associations' do
              let(:values) { {} }

              it 'should not raise an exception' do
                expect { entity.assign_associations(values) }.not_to raise_error
              end

              it 'should not change the entity associations' do
                expect { entity.assign_associations(values) }
                  .not_to change(entity, :associations)
              end

              it 'should not change the entity properties' do
                expect { entity.assign_associations(values) }
                  .not_to change(entity, :properties)
              end
            end

            describe 'with valid String keys' do
              let(:parent)  { Spec::Parent.new(name: 'new parent') }
              let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
              let(:values) do
                {
                  'parent'  => parent,
                  'sibling' => sibling
                }
              end
              let(:expected) do
                {
                  'parent'  => parent,
                  'sibling' => sibling,
                  'child'   => associations['child']
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_associations(values) }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.assign_associations(values)

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(sibling)
              end

              it 'should change the entity associations' do
                expect do
                  rescue_exception { entity.assign_associations(values) }
                end
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect do
                  rescue_exception { entity.assign_associations(values) }
                end
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:parent)  { Spec::Parent.new(name: 'new parent') }
              let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
              let(:values) do
                {
                  parent:  parent,
                  sibling: sibling
                }
              end
              let(:expected) do
                {
                  'parent'  => parent,
                  'sibling' => sibling,
                  'child'   => associations['child']
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_associations(values) }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.assign_associations(values)

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(sibling)
              end

              it 'should change the entity associations' do
                expect do
                  rescue_exception { entity.assign_associations(values) }
                end
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect do
                  rescue_exception { entity.assign_associations(values) }
                end
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          describe 'with empty associations' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.assign_associations(values) }.not_to raise_error
            end

            it 'should not change the entity associations' do
              expect { entity.assign_associations(values) }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { entity.assign_associations(values) }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown association "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_associations(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown association :upc' }

            it 'should raise an exception' do
              expect { entity.assign_associations(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with String property keys' do
            let(:values)        { { 'amplitude' => '1.21 GW' } }
            let(:error_message) { 'unknown association "amplitude"' }

            it 'should raise an exception' do
              expect { entity.assign_associations(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with Symbol property keys' do
            let(:values)        { { amplitude: '1.21 GW' } }
            let(:error_message) { 'unknown association :amplitude' }

            it 'should raise an exception' do
              expect { entity.assign_associations(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:parent)  { Spec::Parent.new }
            let(:sibling) { Spec::Sibling.new }
            let(:values) do
              {
                'parent'  => parent,
                'sibling' => sibling
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => nil,
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.assign_associations(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.assign_associations(values)

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(sibling)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .to change(entity, :associations)
                .to be == expected_associations
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent)  { Spec::Parent.new }
            let(:sibling) { Spec::Sibling.new }
            let(:values) do
              {
                parent:  parent,
                sibling: sibling
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => nil,
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.assign_associations(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.assign_associations(values)

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(sibling)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .to change(entity, :associations)
                .to be == expected_associations
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_associations(values) } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          context 'when the entity has association values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            describe 'with empty associations' do
              let(:values) { {} }

              it 'should not raise an exception' do
                expect { entity.assign_associations(values) }.not_to raise_error
              end

              it 'should not change the entity associations' do
                expect { entity.assign_associations(values) }
                  .not_to change(entity, :associations)
              end

              it 'should not change the entity properties' do
                expect { entity.assign_associations(values) }
                  .not_to change(entity, :properties)
              end
            end

            describe 'with valid String keys' do
              let(:parent)  { Spec::Parent.new }
              let(:sibling) { Spec::Sibling.new }
              let(:values) do
                {
                  'parent'  => parent,
                  'sibling' => sibling
                }
              end
              let(:expected_associations) do
                {
                  'parent'  => parent,
                  'sibling' => sibling,
                  'child'   => associations['child']
                }
              end
              let(:expected_properties) do
                expected_associations.merge(
                  'amplitude' => '1 TW',
                  'frequency' => '1 Hz'
                )
              end

              it 'should not raise an exception' do
                expect { entity.assign_associations(values) }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.assign_associations(values)

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(sibling)
              end

              it 'should change the entity associations' do
                expect { entity.assign_associations(values) }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should change the entity properties' do
                expect { entity.assign_associations(values) }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid Symbol keys' do
              let(:parent)  { Spec::Parent.new }
              let(:sibling) { Spec::Sibling.new }
              let(:values) do
                {
                  parent:  parent,
                  sibling: sibling
                }
              end
              let(:expected_associations) do
                {
                  'parent'  => parent,
                  'sibling' => sibling,
                  'child'   => associations['child']
                }
              end
              let(:expected_properties) do
                expected_associations.merge(
                  'amplitude' => '1 TW',
                  'frequency' => '1 Hz'
                )
              end

              it 'should not raise an exception' do
                expect { entity.assign_associations(values) }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.assign_associations(values)

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(sibling)
              end

              it 'should change the entity associations' do
                expect { entity.assign_associations(values) }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should change the entity properties' do
                expect { entity.assign_associations(values) }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end
          end
        end
      end

      describe '#assign_properties' do
        def rescue_exception
          yield
        rescue ArgumentError
          # Do nothing.
        end

        wrap_context 'when the entity class defines associations' do
          describe 'with empty associations' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should not change the entity associations' do
              expect { entity.assign_properties(values) }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { entity.assign_properties(values) }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'parent' => Spec::Parent.new(name: 'new parent'),
                'upc'    => '12345'
              }
            end
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                parent: Spec::Parent.new(name: 'new parent'),
                upc:    '12345'
              }
            end
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:parent)  { Spec::Parent.new(name: 'new parent') }
            let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
            let(:values) do
              {
                'parent'  => parent,
                'sibling' => sibling
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.assign_properties(values)

              expect(entity)
                .to have_received(:parent=)
                .with(parent)
              expect(entity)
                .to have_received(:sibling=)
                .with(sibling)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :associations)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent)  { Spec::Parent.new(name: 'new parent') }
            let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
            let(:values) do
              {
                parent:  parent,
                sibling: sibling
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.assign_properties(values)

              expect(entity)
                .to have_received(:parent=)
                .with(parent)
              expect(entity)
                .to have_received(:sibling=)
                .with(sibling)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :associations)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          wrap_context 'when the entity has association values' do
            describe 'with empty associations' do
              let(:values) { {} }

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should not change the entity associations' do
                expect { entity.assign_properties(values) }
                  .not_to change(entity, :associations)
              end

              it 'should not change the entity properties' do
                expect { entity.assign_properties(values) }
                  .not_to change(entity, :properties)
              end
            end

            describe 'with valid String keys' do
              let(:parent)  { Spec::Parent.new(name: 'new parent') }
              let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
              let(:values) do
                {
                  'parent'  => parent,
                  'sibling' => sibling
                }
              end
              let(:expected) do
                {
                  'parent'  => parent,
                  'sibling' => sibling,
                  'child'   => associations['child']
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.assign_properties(values)

                expect(entity)
                  .to have_received(:parent=)
                  .with(parent)
                expect(entity)
                  .to have_received(:sibling=)
                  .with(sibling)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:parent)  { Spec::Parent.new(name: 'new parent') }
              let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
              let(:values) do
                {
                  parent:  parent,
                  sibling: sibling
                }
              end
              let(:expected) do
                {
                  'parent'  => parent,
                  'sibling' => sibling,
                  'child'   => associations['child']
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.assign_properties(values)

                expect(entity)
                  .to have_received(:parent=)
                  .with(parent)
                expect(entity)
                  .to have_received(:sibling=)
                  .with(sibling)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          describe 'with empty associations' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should not change the entity associations' do
              expect { entity.assign_properties(values) }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { entity.assign_properties(values) }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:parent)  { Spec::Parent.new(name: 'new parent') }
            let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
            let(:values) do
              {
                'amplitude' => '1 TW',
                'frequency' => '1 Hz',
                'parent'    => parent,
                'sibling'   => sibling
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              )
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.assign_properties(values)

              expect(entity)
                .to have_received(:parent=)
                .with(parent)
              expect(entity)
                .to have_received(:sibling=)
                .with(sibling)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :associations)
                .to be == expected_associations
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent)  { Spec::Parent.new(name: 'new parent') }
            let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
            let(:values) do
              {
                amplitude: '1 TW',
                frequency: '1 Hz',
                parent:    parent,
                sibling:   sibling
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => sibling,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              )
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.assign_properties(values)

              expect(entity)
                .to have_received(:parent=)
                .with(parent)
              expect(entity)
                .to have_received(:sibling=)
                .with(sibling)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :associations)
                .to be == expected_associations
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          context 'when the entity has property values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            describe 'with empty associations' do
              let(:values) { {} }

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should not change the entity associations' do
                expect { entity.assign_properties(values) }
                  .not_to change(entity, :associations)
              end

              it 'should not change the entity properties' do
                expect { entity.assign_properties(values) }
                  .not_to change(entity, :properties)
              end
            end

            describe 'with valid String keys' do
              let(:parent)  { Spec::Parent.new(name: 'new parent') }
              let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
              let(:values) do
                {
                  'amplitude' => '1 TW',
                  'parent'    => parent,
                  'sibling'   => sibling
                }
              end
              let(:expected_associations) do
                {
                  'parent'  => parent,
                  'sibling' => sibling,
                  'child'   => associations['child']
                }
              end
              let(:expected_properties) do
                expected_associations.merge(
                  'amplitude' => generic_properties['amplitude'],
                  'frequency' => '1 Hz'
                )
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.assign_properties(values)

                expect(entity)
                  .to have_received(:parent=)
                  .with(parent)
                expect(entity)
                  .to have_received(:sibling=)
                  .with(sibling)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid Symbol keys' do
              let(:parent)  { Spec::Parent.new(name: 'new parent') }
              let(:sibling) { Spec::Sibling.new(name: 'new sibling') }
              let(:values) do
                {
                  amplitude: '1 TW',
                  parent:    parent,
                  sibling:   sibling
                }
              end
              let(:expected_associations) do
                {
                  'parent'  => parent,
                  'sibling' => sibling,
                  'child'   => associations['child']
                }
              end
              let(:expected_properties) do
                expected_associations.merge(
                  'amplitude' => generic_properties['amplitude'],
                  'frequency' => '1 Hz'
                )
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.assign_properties(values)

                expect(entity)
                  .to have_received(:parent=)
                  .with(parent)
                expect(entity)
                  .to have_received(:sibling=)
                  .with(sibling)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end
          end
        end
      end

      describe '#associations' do
        include_examples 'should define reader', :associations, {}

        it 'should return a copy of the associations' do
          expect { entity.associations['impostor'] = Object.new.freeze }
            .not_to change(entity, :associations)
        end

        wrap_context 'when the entity class defines associations' do
          let(:expected) do
            {
              'parent'  => nil,
              'sibling' => nil,
              'child'   => nil
            }
          end

          it { expect(entity.associations).to be == expected }

          wrap_context 'when the entity has association values' do
            it { expect(entity.associations).to be == associations }
          end
        end

        wrap_context 'with an entity subclass' do
          it { expect(entity.associations).to be == {} }

          wrap_context 'when the entity class defines associations' do
            let(:expected) do
              {
                'parent'  => nil,
                'sibling' => nil,
                'child'   => nil
              }
            end

            it { expect(entity.associations).to be == expected }

            wrap_context 'when the entity has association values' do
              it { expect(entity.associations).to be == associations }
            end
          end

          wrap_context 'when the subclass defines associations' do
            let(:expected) do
              { 'bestie' => nil }
            end

            it { expect(entity.associations).to be == expected }

            wrap_context 'when the entity has association values' do
              let(:associations) do
                { 'bestie' => Spec::Bestie.new(name: 'original bestie') }
              end

              it { expect(entity.associations).to be == associations }
            end
          end

          context 'when the struct and the subclass define associations' do
            include_context 'when the entity class defines associations'
            include_context 'when the subclass defines associations'

            let(:expected) do
              {
                'parent'  => nil,
                'sibling' => nil,
                'child'   => nil,
                'bestie'  => nil
              }
            end

            it { expect(entity.associations).to be == expected }

            wrap_context 'when the entity has association values' do
              let(:associations) do
                {
                  'parent'  => Spec::Parent.new(name: 'original parent'),
                  'sibling' => Spec::Sibling.new(name: 'original sibling'),
                  'child'   => Spec::Child.new(name: 'original child'),
                  'bestie'  => Spec::Bestie.new(name: 'original bestie')
                }
              end

              it { expect(entity.associations).to be == associations }
            end
          end
        end
      end

      describe '#associations=' do
        def rescue_exception
          yield
        rescue ArgumentError
          # Do nothing.
        end

        include_examples 'should define writer', :associations=

        describe 'with nil' do
          let(:error_message) { 'associations must be a Hash' }

          it 'should raise an exception' do
            expect { entity.associations = nil }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) { 'associations must be a Hash' }

          it 'should raise an exception' do
            expect { entity.associations = Object.new.freeze }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with nil keys' do
          let(:values)        { { nil => 'value' } }
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.associations = values }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with Object keys' do
          let(:values)        { { Object.new.freeze => 'value' } }
          let(:error_message) { 'association is not a String or a Symbol' }

          it 'should raise an exception' do
            expect { entity.associations = values }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with empty String keys' do
          let(:values)        { { '' => 'value' } }
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.associations = values }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with empty Symbol keys' do
          let(:values)        { { '': 'value' } }
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.associations = values }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with empty associations' do
          let(:values) { {} }

          it { expect { entity.associations = values }.not_to raise_error }

          it 'should not change the entity associations' do
            expect { entity.associations = values }
              .not_to change(entity, :associations)
          end

          it 'should not change the entity properties' do
            expect { entity.associations = values }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid String keys' do
          let(:values)        { { 'phase_angle' => 'π' } }
          let(:error_message) { 'unknown association "phase_angle"' }

          it 'should raise an exception' do
            expect { entity.associations = values }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the entity associations' do
            expect { rescue_exception { entity.associations = values } }
              .not_to change(entity, :associations)
          end

          it 'should not change the entity properties' do
            expect { rescue_exception { entity.associations = values } }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid Symbol keys' do
          let(:values)        { { phase_angle: 'π' } }
          let(:error_message) { 'unknown association :phase_angle' }

          it 'should raise an exception' do
            expect { entity.associations = values }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the entity associations' do
            expect { rescue_exception { entity.associations = values } }
              .not_to change(entity, :associations)
          end

          it 'should not change the entity properties' do
            expect { rescue_exception { entity.associations = values } }
              .not_to change(entity, :properties)
          end
        end

        wrap_context 'when the entity class defines associations' do
          describe 'with empty associations' do
            let(:values) { {} }

            it { expect { entity.associations = values }.not_to raise_error }

            it 'should not change the entity associations' do
              expect { entity.associations = values }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { entity.associations = values }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'phase_angle' => 'π' } }
            let(:error_message) { 'unknown association "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.associations = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { phase_angle: 'π' } }
            let(:error_message) { 'unknown association :phase_angle' }

            it 'should raise an exception' do
              expect { entity.associations = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'parent'  => Spec::Parent.new(name: 'new parent'),
                'sibling' => nil,
                'upc'     => '12345'
              }
            end
            let(:error_message) { 'unknown association "upc"' }

            it 'should raise an exception' do
              expect { entity.associations = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                parent:  Spec::Parent.new(name: 'new parent'),
                sibling: nil,
                upc:     '12345'
              }
            end
            let(:error_message) { 'unknown association :upc' }

            it 'should raise an exception' do
              expect { entity.associations = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }
            let(:values) do
              {
                'parent'  => parent,
                'sibling' => nil
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => nil,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { entity.associations = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.associations = values

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(nil)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .to change(entity, :associations)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }
            let(:values) do
              {
                parent:  parent,
                sibling: nil
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => nil,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { entity.associations = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.associations = values

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(nil)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .to change(entity, :associations)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          wrap_context 'when the entity has association values' do
            describe 'with empty associations' do
              let(:values) { {} }
              let(:expected) do
                {
                  'parent'  => nil,
                  'sibling' => nil,
                  'child'   => nil
                }
              end

              it { expect { entity.associations = values }.not_to raise_error }

              it 'should clear the entity associations' do
                expect { entity.associations = values }
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { entity.associations = values }
                  .to change(entity, :associations)
                  .to be >= expected
              end
            end

            describe 'with valid String keys' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }
              let(:values) do
                {
                  'parent'  => parent,
                  'sibling' => nil
                }
              end
              let(:expected) do
                {
                  'parent'  => parent,
                  'sibling' => nil,
                  'child'   => nil
                }
              end

              it 'should not raise an exception' do
                expect { entity.associations = values }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.associations = values

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(nil)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.associations = values } }
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.associations = values } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }
              let(:values) do
                {
                  parent:  parent,
                  sibling: nil
                }
              end
              let(:expected) do
                {
                  'parent'  => parent,
                  'sibling' => nil,
                  'child'   => nil
                }
              end

              it 'should not raise an exception' do
                expect { entity.associations = values }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.associations = values

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(nil)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.associations = values } }
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.associations = values } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          describe 'with empty associations' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.associations = values }.not_to raise_error
            end

            it 'should not change the entity associations' do
              expect { entity.associations = values }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { entity.associations = values }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'phase_angle' => 'π' } }
            let(:error_message) { 'unknown association "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.associations = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { phase_angle: 'π' } }
            let(:error_message) { 'unknown association :phase_angle' }

            it 'should raise an exception' do
              expect { entity.associations = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with String property keys' do
            let(:values)        { { 'amplitude' => '1.21 GW' } }
            let(:error_message) { 'unknown association "amplitude"' }

            it 'should raise an exception' do
              expect { entity.associations = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with Symbol property keys' do
            let(:values)        { { amplitude: '1.21 GW' } }
            let(:error_message) { 'unknown association :amplitude' }

            it 'should raise an exception' do
              expect { entity.associations = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }
            let(:values) do
              {
                'parent'  => parent,
                'sibling' => nil
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => nil,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => nil,
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.associations = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.associations = values

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(nil)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .to change(entity, :associations)
                .to be == expected_associations
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }
            let(:values) do
              {
                parent:  parent,
                sibling: nil
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => nil,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => nil,
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.associations = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.associations = values

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(nil)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.associations = values } }
                .to change(entity, :associations)
                .to be == expected_associations
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.associations = values } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          context 'when the entity has association values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            describe 'with empty associations' do
              let(:values) { {} }
              let(:expected_associations) do
                {
                  'parent'  => nil,
                  'sibling' => nil,
                  'child'   => nil
                }
              end
              let(:expected_properties) do
                expected_associations.merge(generic_properties)
              end

              it 'should not raise an exception' do
                expect { entity.associations = values }.not_to raise_error
              end

              it 'should clear the entity associations' do
                expect { entity.associations = values }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should not change the non-association properties' do
                expect { entity.associations = values }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid String keys' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }
              let(:values) do
                {
                  'parent'  => parent,
                  'sibling' => nil
                }
              end
              let(:expected_associations) do
                {
                  'parent'  => parent,
                  'sibling' => nil,
                  'child'   => nil
                }
              end
              let(:expected_properties) do
                expected_associations.merge(generic_properties)
              end

              it 'should not raise an exception' do
                expect { entity.associations = values }.not_to raise_error
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.associations = values } }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should not change the non-association properties' do
                expect { rescue_exception { entity.associations = values } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid Symbol keys' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }
              let(:values) do
                {
                  parent:  parent,
                  sibling: nil
                }
              end
              let(:expected_associations) do
                {
                  'parent'  => parent,
                  'sibling' => nil,
                  'child'   => nil
                }
              end
              let(:expected_properties) do
                expected_associations.merge(generic_properties)
              end

              it 'should not raise an exception' do
                expect { entity.associations = values }.not_to raise_error
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.associations = values } }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should not change the non-association properties' do
                expect { rescue_exception { entity.associations = values } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end
          end
        end
      end

      describe '#inspect' do
        def inspect_association(associated_entity)
          return 'nil' if associated_entity.nil?

          associated_entity.inspect_with_options(associations: false)
        end

        wrap_context 'when the entity class defines associations' do
          let(:expected) do
            "#<#{described_class.name} " \
              "parent: #{inspect_association(entity.parent)} " \
              "sibling: #{inspect_association(entity.sibling)} " \
              "child: #{inspect_association(entity.child)}" \
              '>'
          end

          it { expect(entity.inspect).to be == expected }

          wrap_context 'when the entity has association values' do
            it { expect(entity.inspect).to be == expected }
          end
        end

        context 'when the entity class defines an inverse association' do
          let(:entity_class) do
            defined?(super()) ? super() : Spec::EntityClass
          end
          let(:expected) do
            "#<#{described_class.name} " \
              "reference: #{inspect_association(entity.reference)}" \
              '>'
          end

          example_class 'Spec::Reference' do |klass|
            klass.include Stannum::Entity

            klass.define_association :one,
              :entity,
              class_name: entity_class.name
          end

          before(:example) do
            entity_class.define_association :one,
              'reference',
              class_name: 'Spec::Reference',
              inverse:    :entity
          end

          it { expect(entity.inspect).to be == expected }

          context 'when the entity has association values' do
            let(:associations) do
              { 'reference' => Spec::Reference.new }
            end
            let(:properties) do
              defined?(super()) ? super().merge(associations) : associations
            end

            it { expect(entity.inspect).to be == expected }
          end
        end

        context 'when the entity class defines associations and properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          let(:expected) do
            "#<#{described_class.name} " \
              "parent: #{inspect_association(entity.parent)} " \
              "sibling: #{inspect_association(entity.sibling)} " \
              "child: #{inspect_association(entity.child)} " \
              "amplitude: #{entity['amplitude'].inspect} " \
              "frequency: #{entity['frequency'].inspect}" \
              '>'
          end

          it { expect(entity.inspect).to be == expected }

          context 'when the entity has association values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            it { expect(entity.inspect).to be == expected }
          end
        end
      end

      describe '#inspect_with_options' do
        let(:options) { {} }

        def inspect_association(associated_entity)
          return 'nil' if associated_entity.nil?

          associated_entity.inspect_with_options(associations: false)
        end

        wrap_context 'when the entity class defines associations' do
          let(:expected) do
            "#<#{described_class.name} " \
              "parent: #{inspect_association(entity.parent)} " \
              "sibling: #{inspect_association(entity.sibling)} " \
              "child: #{inspect_association(entity.child)}" \
              '>'
          end

          it 'should format the entity' do
            expect(entity.inspect_with_options(**options)).to be == expected
          end

          wrap_context 'when the entity has association values' do
            it 'should format the entity' do
              expect(entity.inspect_with_options(**options)).to be == expected
            end
          end

          describe 'with associations: false' do
            let(:options)  { { associations: false } }
            let(:expected) { "#<#{described_class.name}>" }

            it 'should format the entity' do
              expect(entity.inspect_with_options(**options)).to be == expected
            end

            wrap_context 'when the entity has association values' do
              it 'should format the entity' do
                expect(entity.inspect_with_options(**options)).to be == expected
              end
            end
          end
        end

        context 'when the entity class defines an inverse association' do
          let(:entity_class) do
            defined?(super()) ? super() : Spec::EntityClass
          end
          let(:expected) do
            "#<#{described_class.name} " \
              "reference: #{inspect_association(entity.reference)}" \
              '>'
          end

          example_class 'Spec::Reference' do |klass|
            klass.include Stannum::Entity

            klass.define_association :one,
              :entity,
              class_name: entity_class.name
          end

          before(:example) do
            entity_class.define_association :one,
              'reference',
              class_name: 'Spec::Reference',
              inverse:    :entity
          end

          it 'should format the entity' do
            expect(entity.inspect_with_options(**options)).to be == expected
          end

          context 'when the entity has association values' do
            let(:associations) do
              { 'reference' => Spec::Reference.new }
            end
            let(:properties) do
              defined?(super()) ? super().merge(associations) : associations
            end

            it 'should format the entity' do
              expect(entity.inspect_with_options(**options)).to be == expected
            end
          end

          describe 'with associations: false' do
            let(:options)  { { associations: false } }
            let(:expected) { "#<#{described_class.name}>" }

            it 'should format the entity' do
              expect(entity.inspect_with_options(**options)).to be == expected
            end

            context 'when the entity has association values' do
              let(:associations) do
                { 'reference' => Spec::Reference.new }
              end
              let(:properties) do
                defined?(super()) ? super().merge(associations) : associations
              end

              it 'should format the entity' do
                expect(entity.inspect_with_options(**options)).to be == expected
              end
            end
          end
        end

        context 'when the entity class defines associations and properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          let(:expected) do
            "#<#{described_class.name} " \
              "parent: #{inspect_association(entity.parent)} " \
              "sibling: #{inspect_association(entity.sibling)} " \
              "child: #{inspect_association(entity.child)} " \
              "amplitude: #{entity['amplitude'].inspect} " \
              "frequency: #{entity['frequency'].inspect}" \
              '>'
          end

          it 'should format the entity' do
            expect(entity.inspect_with_options(**options)).to be == expected
          end

          wrap_context 'when the entity has association values' do
            it 'should format the entity' do
              expect(entity.inspect_with_options(**options)).to be == expected
            end
          end

          describe 'with associations: false' do
            let(:options)  { { associations: false } }
            let(:expected) do
              "#<#{described_class.name} " \
                "amplitude: #{entity['amplitude'].inspect} " \
                "frequency: #{entity['frequency'].inspect}" \
                '>'
            end

            it 'should format the entity' do
              expect(entity.inspect_with_options(**options)).to be == expected
            end

            wrap_context 'when the entity has association values' do
              it 'should format the entity' do
                expect(entity.inspect_with_options(**options)).to be == expected
              end
            end
          end

          describe 'with properties: false' do
            let(:options) { super().merge(properties: false) }
            let(:expected) do
              "#<#{described_class.name} " \
                "parent: #{inspect_association(entity.parent)} " \
                "sibling: #{inspect_association(entity.sibling)} " \
                "child: #{inspect_association(entity.child)}" \
                '>'
            end

            it 'should format the entity' do
              expect(entity.inspect_with_options(**options)).to be == expected
            end

            context 'when the entity has association values' do
              include_context 'when the entity has association values'
              include_context 'when the entity has property values'

              let(:properties) { generic_properties.merge(associations) }

              it 'should format the entity' do
                expect(entity.inspect_with_options(**options)).to be == expected
              end
            end
          end
        end
      end

      describe '#properties' do
        wrap_context 'when the entity class defines associations' do
          let(:expected) do
            {
              'parent'  => nil,
              'sibling' => nil,
              'child'   => nil
            }
          end

          it { expect(entity.properties).to be == expected }

          wrap_context 'when the entity has association values' do
            it { expect(entity.properties).to be == associations }
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          let(:expected) do
            {
              'parent'    => nil,
              'sibling'   => nil,
              'child'     => nil,
              'amplitude' => nil,
              'frequency' => nil
            }
          end

          it { expect(entity.properties).to be == expected }

          context 'when the entity has association values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            it { expect(entity.properties).to be == properties }
          end
        end
      end

      describe '#properties=' do
        def rescue_exception
          yield
        rescue ArgumentError
          # Do nothing.
        end

        wrap_context 'when the entity class defines associations' do
          describe 'with empty properties' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should not change the entity associations' do
              expect { entity.properties = values }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { entity.properties = values }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'parent'  => Spec::Parent.new(name: 'new parent'),
                'sibling' => nil,
                'upc'     => '12345'
              }
            end
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                parent:  Spec::Parent.new(name: 'new parent'),
                sibling: nil,
                upc:     '12345'
              }
            end
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }
            let(:values) do
              {
                'parent'  => parent,
                'sibling' => nil
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => nil,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.properties = values

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(nil)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :associations)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }
            let(:values) do
              {
                parent:  parent,
                sibling: nil
              }
            end
            let(:expected) do
              {
                'parent'  => parent,
                'sibling' => nil,
                'child'   => nil
              }
            end

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.properties = values

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(nil)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :associations)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          wrap_context 'when the entity has association values' do
            describe 'with empty associations' do
              let(:values) { {} }
              let(:expected) do
                {
                  'parent'  => nil,
                  'sibling' => nil,
                  'child'   => nil
                }
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should clear the entity associations' do
                expect { entity.properties = values }
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should clear the entity properties' do
                expect { entity.properties = values }
                  .to change(entity, :properties)
                  .to be == expected
              end
            end

            describe 'with valid String keys' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }
              let(:values) do
                {
                  'parent'  => parent,
                  'sibling' => nil
                }
              end
              let(:expected) do
                {
                  'parent'  => parent,
                  'sibling' => nil,
                  'child'   => nil
                }
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.properties = values

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(nil)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }
              let(:values) do
                {
                  parent:  parent,
                  sibling: nil
                }
              end
              let(:expected) do
                {
                  'parent'  => parent,
                  'sibling' => nil,
                  'child'   => nil
                }
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.properties = values

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(nil)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :associations)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          describe 'with empty properties' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should not change the entity associations' do
              expect { entity.properties = values }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { entity.properties = values }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'amplitude' => '1.21 GW',
                'parent'    => Spec::Parent.new(name: 'new parent'),
                'sibling'   => nil,
                'upc'       => '12345'
              }
            end
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                amplitude: '1.21 GW',
                parent:    Spec::Parent.new(name: 'new parent'),
                sibling:   nil,
                upc:       '12345'
              }
            end
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :associations)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }
            let(:values) do
              {
                'amplitude' => '1.21 GW',
                'parent'    => parent,
                'sibling'   => nil
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => nil,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => '1.21 GW',
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.properties = values

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(nil)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :associations)
                .to be == expected_associations
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:parent) { Spec::Parent.new(name: 'new parent') }
            let(:values) do
              {
                amplitude: '1.21 GW',
                parent:    parent,
                sibling:   nil
              }
            end
            let(:expected_associations) do
              {
                'parent'  => parent,
                'sibling' => nil,
                'child'   => nil
              }
            end
            let(:expected_properties) do
              expected_associations.merge(
                'amplitude' => '1.21 GW',
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:parent=)
              allow(entity).to receive(:sibling=)

              entity.properties = values

              expect(entity).to have_received(:parent=).with(parent)
              expect(entity).to have_received(:sibling=).with(nil)
            end

            it 'should change the entity associations' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :associations)
                .to be == expected_associations
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          context 'when the entity has attribute values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            describe 'with empty properties' do
              let(:values) { {} }
              let(:expected_associations) do
                {
                  'parent'  => nil,
                  'sibling' => nil,
                  'child'   => nil
                }
              end
              let(:expected_properties) do
                expected_associations.merge(
                  'amplitude' => nil,
                  'frequency' => nil
                )
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should clear the entity associations' do
                expect { entity.properties = values }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should clear the entity properties' do
                expect { entity.properties = values }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid String keys' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }
              let(:values) do
                {
                  'amplitude' => '1.21 GW',
                  'parent'    => parent,
                  'sibling'   => nil
                }
              end
              let(:expected_associations) do
                {
                  'parent'  => parent,
                  'sibling' => nil,
                  'child'   => nil
                }
              end
              let(:expected_properties) do
                expected_associations.merge(
                  'amplitude' => '1.21 GW',
                  'frequency' => nil
                )
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.properties = values

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(nil)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid Symbol keys' do
              let(:parent) { Spec::Parent.new(name: 'new parent') }
              let(:values) do
                {
                  amplitude: '1.21 GW',
                  parent:    parent,
                  sibling:   nil
                }
              end
              let(:expected_associations) do
                {
                  'parent'  => parent,
                  'sibling' => nil,
                  'child'   => nil
                }
              end
              let(:expected_properties) do
                expected_associations.merge(
                  'amplitude' => '1.21 GW',
                  'frequency' => nil
                )
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should call the writer methods', :aggregate_failures do
                allow(entity).to receive(:parent=)
                allow(entity).to receive(:sibling=)

                entity.properties = values

                expect(entity).to have_received(:parent=).with(parent)
                expect(entity).to have_received(:sibling=).with(nil)
              end

              it 'should change the entity associations' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :associations)
                  .to be == expected_associations
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end
          end
        end
      end

      describe '#read_association' do
        it 'should define the method' do
          expect(entity)
            .to respond_to(:read_association)
            .with(1).argument
            .and_keywords(:safe)
        end

        describe 'with key: nil' do
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.read_association(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an Object' do
          let(:error_message) { 'association is not a String or a Symbol' }

          it 'should raise an exception' do
            expect { entity.read_association(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an empty String' do
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.read_association('') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an empty Symbol' do
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.read_association(:'') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an invalid String' do
          let(:error_message) { 'unknown association "phase_angle"' }

          it 'should raise an exception' do
            expect { entity.read_association('phase_angle') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an invalid Symbol' do
          let(:error_message) { 'unknown association :phase_angle' }

          it 'should raise an exception' do
            expect { entity.read_association(:phase_angle) }
              .to raise_error ArgumentError, error_message
          end
        end

        wrap_context 'when the entity class defines associations' do
          describe 'with key: an invalid String' do
            let(:error_message) { 'unknown association "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.read_association('phase_angle') }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an invalid Symbol' do
            let(:error_message) { 'unknown association :phase_angle' }

            it 'should raise an exception' do
              expect { entity.read_association(:phase_angle) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with a valid String' do
            it { expect(entity.read_association('parent')).to be nil }
          end

          describe 'with a valid Symbol' do
            it { expect(entity.read_association(:parent)).to be nil }
          end

          wrap_context 'when the entity has association values' do
            describe 'with a valid String' do
              it 'should return the association value' do
                expect(entity.read_association('parent'))
                  .to be == associations['parent']
              end
            end

            describe 'with a valid Symbol' do
              it 'should return the association value' do
                expect(entity.read_association(:parent))
                  .to be == associations['parent']
              end
            end
          end
        end

        wrap_context 'when the entity class defines properties' do
          include_context 'when the entity has property values'

          describe 'with a property String' do
            let(:error_message) { 'unknown association "amplitude"' }

            it 'should raise an exception' do
              expect { entity.read_association('amplitude') }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with a property Symbol' do
            let(:error_message) { 'unknown association :amplitude' }

            it 'should raise an exception' do
              expect { entity.read_association(:amplitude) }
                .to raise_error ArgumentError, error_message
            end
          end
        end

        describe 'with safe: false' do
          describe 'with key: nil' do
            it 'should get the association value' do
              expect(entity.read_association(nil, safe: false)).to be nil
            end
          end

          describe 'with key: an Object' do
            it 'should get the association value' do
              expect(entity.read_association(Object.new.freeze, safe: false))
                .to be nil
            end
          end

          describe 'with key: an empty String' do
            it 'should get the association value' do
              expect(entity.read_association('', safe: false)).to be nil
            end
          end

          describe 'with key: an empty Symbol' do
            it 'should get the association value' do
              expect(entity.read_association(:'', safe: false)).to be nil
            end
          end

          describe 'with key: an invalid String' do
            it 'should get the association value' do
              expect(entity.read_association('phase_angle', safe: false))
                .to be nil
            end
          end

          describe 'with key: an invalid Symbol' do
            it 'should get the association value' do
              expect(entity.read_association(:phase_angle, safe: false))
                .to be nil
            end
          end

          wrap_context 'when the entity class defines associations' do
            describe 'with key: an invalid String' do
              it 'should get the association value' do
                expect(entity.read_association('phase_angle', safe: false))
                  .to be nil
              end
            end

            describe 'with key: an invalid Symbol' do
              it 'should get the association value' do
                expect(entity.read_association(:phase_angle, safe: false))
                  .to be nil
              end
            end

            describe 'with key: a valid String' do
              it 'should get the association value' do
                expect(entity.read_association('parent', safe: false)).to be nil
              end
            end

            describe 'with key: a valid Symbol' do
              it 'should get the association value' do
                expect(entity.read_association(:parent, safe: false)).to be nil
              end
            end

            wrap_context 'when the entity has association values' do
              describe 'with key: a valid String' do
                it 'should get the association value' do
                  expect(entity.read_association('parent', safe: false))
                    .to be == associations['parent']
                end
              end

              describe 'with key: a valid Symbol' do
                it 'should get the association value' do
                  expect(entity.read_association(:parent, safe: false))
                    .to be == associations['parent']
                end
              end
            end
          end

          wrap_context 'when the entity class defines properties' do
            include_context 'when the entity has property values'

            describe 'with a property String' do
              it 'should get the association value' do
                expect(entity.read_association('amplitude', safe: false))
                  .to be nil
              end
            end

            describe 'with a property Symbol' do
              it 'should get the association value' do
                expect(entity.read_association(:amplitude, safe: false))
                  .to be nil
              end
            end
          end
        end

        describe 'with safe: true' do
          describe 'with key: nil' do
            let(:error_message) { "association can't be blank" }

            it 'should raise an exception' do
              expect { entity.read_association(nil, safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an Object' do
            let(:error_message) { 'association is not a String or a Symbol' }

            it 'should raise an exception' do
              expect { entity.read_association(Object.new.freeze, safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an empty String' do
            let(:error_message) { "association can't be blank" }

            it 'should raise an exception' do
              expect { entity.read_association('', safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an empty Symbol' do
            let(:error_message) { "association can't be blank" }

            it 'should raise an exception' do
              expect { entity.read_association(:'', safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an invalid String' do
            let(:error_message) { 'unknown association "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.read_association('phase_angle', safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an invalid Symbol' do
            let(:error_message) { 'unknown association :phase_angle' }

            it 'should raise an exception' do
              expect { entity.read_association(:phase_angle, safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          wrap_context 'when the entity class defines associations' do
            describe 'with key: an invalid String' do
              let(:error_message) { 'unknown association "phase_angle"' }

              it 'should raise an exception' do
                expect { entity.read_association('phase_angle', safe: true) }
                  .to raise_error ArgumentError, error_message
              end
            end

            describe 'with key: an invalid Symbol' do
              let(:error_message) { 'unknown association :phase_angle' }

              it 'should raise an exception' do
                expect { entity.read_association(:phase_angle, safe: true) }
                  .to raise_error ArgumentError, error_message
              end
            end

            describe 'with a valid String' do
              it 'should return the association value' do
                expect(entity.read_association('parent', safe: true)).to be nil
              end
            end

            describe 'with a valid Symbol' do
              it 'should return the association value' do
                expect(entity.read_association(:parent, safe: true)).to be nil
              end
            end

            wrap_context 'when the entity has association values' do
              describe 'with a valid String' do
                it 'should return the association value' do
                  expect(entity.read_association('parent', safe: true))
                    .to be == associations['parent']
                end
              end

              describe 'with a valid Symbol' do
                it 'should return the association value' do
                  expect(entity.read_association(:parent, safe: true))
                    .to be == associations['parent']
                end
              end
            end
          end

          wrap_context 'when the entity class defines properties' do
            include_context 'when the entity has property values'

            describe 'with a property String' do
              let(:error_message) { 'unknown association "amplitude"' }

              it 'should raise an exception' do
                expect { entity.read_association('amplitude', safe: true) }
                  .to raise_error ArgumentError, error_message
              end
            end

            describe 'with a property Symbol' do
              let(:error_message) { 'unknown association :amplitude' }

              it 'should raise an exception' do
                expect { entity.read_association(:amplitude, safe: true) }
                  .to raise_error ArgumentError, error_message
              end
            end
          end
        end
      end

      describe '#to_h' do
        wrap_context 'when the entity class defines associations' do
          let(:expected) do
            {
              'parent'  => nil,
              'sibling' => nil,
              'child'   => nil
            }
          end

          it { expect(entity.to_h).to be == expected }

          wrap_context 'when the entity has association values' do
            it { expect(entity.to_h).to be == associations }
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines associations'
          include_context 'when the entity class defines properties'

          let(:expected) do
            {
              'parent'    => nil,
              'sibling'   => nil,
              'child'     => nil,
              'amplitude' => nil,
              'frequency' => nil
            }
          end

          it { expect(entity.to_h).to be == expected }

          context 'when the entity has association values' do
            include_context 'when the entity has association values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(associations) }

            it { expect(entity.to_h).to be == properties }
          end
        end
      end

      describe '#write_association' do
        it 'should define the method' do
          expect(entity)
            .to respond_to(:write_association)
            .with(2).arguments
            .and_keywords(:safe)
        end

        describe 'with key: nil' do
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.write_association(nil, nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an Object' do
          let(:error_message) { 'association is not a String or a Symbol' }

          it 'should raise an exception' do
            expect { entity.write_association(Object.new.freeze, nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an empty String' do
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.write_association('', nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an empty Symbol' do
          let(:error_message) { "association can't be blank" }

          it 'should raise an exception' do
            expect { entity.write_association(:'', nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an invalid String' do
          let(:error_message) { 'unknown association "phase_angle"' }

          it 'should raise an exception' do
            expect { entity.write_association('phase_angle', nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with key: an invalid Symbol' do
          let(:error_message) { 'unknown association :phase_angle' }

          it 'should raise an exception' do
            expect { entity.write_association(:phase_angle, nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        wrap_context 'when the entity class defines associations' do
          describe 'with key: an invalid String' do
            let(:error_message) { 'unknown association "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.write_association('phase_angle', nil) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an invalid Symbol' do
            let(:error_message) { 'unknown association :phase_angle' }

            it 'should raise an exception' do
              expect { entity.write_association(:phase_angle, nil) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: a valid String' do
            describe 'with nil' do
              it 'should not change the association' do
                expect { entity.write_association('parent', nil) }
                  .not_to change(entity, :parent)
              end
            end

            describe 'with a value' do
              let(:value) { Spec::Parent.new(name: 'new parent') }

              it 'should set the association' do
                expect { entity.write_association('parent', value) }
                  .to change(entity, :parent)
                  .to be == value
              end
            end
          end

          describe 'with key: a valid Symbol' do
            describe 'with nil' do
              it 'should not change the association' do
                expect { entity.write_association(:parent, nil) }
                  .not_to change(entity, :parent)
              end
            end

            describe 'with a value' do
              let(:value) { Spec::Parent.new(name: 'new parent') }

              it 'should set the association' do
                expect { entity.write_association(:parent, value) }
                  .to change(entity, :parent)
                  .to be == value
              end
            end
          end

          wrap_context 'when the entity has association values' do
            describe 'with key: a valid String' do
              describe 'with nil' do
                it 'should clear the association' do
                  expect { entity.write_association('parent', nil) }
                    .to change(entity, :parent)
                    .to be nil
                end
              end

              describe 'with a value' do
                let(:value) { Spec::Parent.new(name: 'new parent') }

                it 'should set the association' do
                  expect { entity.write_association('parent', value) }
                    .to change(entity, :parent)
                    .to be == value
                end
              end
            end

            describe 'with key: a valid Symbol' do
              describe 'with nil' do
                it 'should clear the association' do
                  expect { entity.write_association(:parent, nil) }
                    .to change(entity, :parent)
                    .to be nil
                end
              end

              describe 'with a value' do
                let(:value) { Spec::Parent.new(name: 'new parent') }

                it 'should set the association' do
                  expect { entity.write_association(:parent, value) }
                    .to change(entity, :parent)
                    .to be == value
                end
              end
            end
          end
        end

        wrap_context 'when the entity class defines properties' do
          describe 'with key: an invalid String' do
            let(:error_message) { 'unknown association "amplitude"' }

            it 'should raise an exception' do
              expect { entity.write_association('amplitude', nil) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an invalid Symbol' do
            let(:error_message) { 'unknown association :amplitude' }

            it 'should raise an exception' do
              expect { entity.write_association(:amplitude, nil) }
                .to raise_error ArgumentError, error_message
            end
          end
        end

        describe 'with safe: false' do
          let(:value) { Object.new.freeze }

          describe 'with key: nil' do
            it 'should force update the associations' do
              expect { entity.write_association(nil, value, safe: false) }
                .to change(entity, :associations)
                .to be >= { '' => value }
            end
          end

          describe 'with key: an Object' do
            let(:key) { Object.new.freeze }

            it 'should force update the associations' do
              expect { entity.write_association(key, value, safe: false) }
                .to change(entity, :associations)
                .to be >= { key.to_s => value }
            end
          end

          describe 'with key: an empty String' do
            it 'should force update the associations' do
              expect { entity.write_association('', value, safe: false) }
                .to change(entity, :associations)
                .to be >= { '' => value }
            end
          end

          describe 'with key: an empty Symbol' do
            it 'should force update the associations' do
              expect { entity.write_association(:'', value, safe: false) }
                .to change(entity, :associations)
                .to be >= { '' => value }
            end
          end

          describe 'with key: an invalid String' do
            it 'should force update the associations' do
              expect do
                entity.write_association('phase_angle', value, safe: false)
              end
                .to change(entity, :associations)
                .to be >= { 'phase_angle' => value }
            end
          end

          describe 'with key: an invalid Symbol' do
            it 'should force update the associations' do
              expect do
                entity.write_association(:phase_angle, value, safe: false)
              end
                .to change(entity, :associations)
                .to be >= { 'phase_angle' => value }
            end
          end

          wrap_context 'when the entity class defines associations' do
            describe 'with key: an invalid String' do
              it 'should force update the associations' do
                expect do
                  entity.write_association('phase_angle', value, safe: false)
                end
                  .to change(entity, :associations)
                  .to be >= { 'phase_angle' => value }
              end
            end

            describe 'with key: an invalid Symbol' do
              it 'should force update the associations' do
                expect do
                  entity.write_association(:phase_angle, value, safe: false)
                end
                  .to change(entity, :associations)
                  .to be >= { 'phase_angle' => value }
              end
            end

            describe 'with key: a valid String' do
              describe 'with nil' do
                it 'should not change the association' do
                  expect do
                    entity.write_association('parent', nil, safe: false)
                  end
                    .not_to change(entity, :parent)
                end
              end

              describe 'with a value' do
                let(:value) { Spec::Parent.new(name: 'new parent') }

                it 'should set the association' do
                  expect do
                    entity.write_association('parent', value, safe: false)
                  end
                    .to change(entity, :parent)
                    .to be == value
                end
              end
            end

            describe 'with key: a valid Symbol' do
              describe 'with nil' do
                it 'should not change the association' do
                  expect do
                    entity.write_association(:parent, nil, safe: false)
                  end
                    .not_to change(entity, :parent)
                end
              end

              describe 'with a value' do
                let(:value) { Spec::Parent.new(name: 'new parent') }

                it 'should set the association' do
                  expect do
                    entity.write_association(:parent, value, safe: false)
                  end
                    .to change(entity, :parent)
                    .to be == value
                end
              end
            end

            wrap_context 'when the entity has association values' do
              describe 'with key: a valid String' do
                describe 'with nil' do
                  it 'should clear the association' do
                    expect do
                      entity.write_association('parent', nil, safe: false)
                    end
                      .to change(entity, :parent)
                      .to be nil
                  end
                end

                describe 'with a value' do
                  let(:value) { Spec::Parent.new(name: 'new parent') }

                  it 'should set the association' do
                    expect do
                      entity.write_association('parent', value, safe: false)
                    end
                      .to change(entity, :parent)
                      .to be == value
                  end
                end
              end

              describe 'with key: a valid Symbol' do
                describe 'with nil' do
                  it 'should clear the association' do
                    expect do
                      entity.write_association(:parent, nil, safe: false)
                    end
                      .to change(entity, :parent)
                      .to be nil
                  end
                end

                describe 'with a value' do
                  let(:value) { Spec::Parent.new(name: 'new parent') }

                  it 'should set the association' do
                    expect do
                      entity.write_association(:parent, value, safe: false)
                    end
                      .to change(entity, :parent)
                      .to be == value
                  end
                end
              end
            end
          end

          wrap_context 'when the entity class defines properties' do
            describe 'with key: an invalid String' do
              it 'should force update the associations' do
                expect do
                  entity.write_association('amplitude', value, safe: false)
                end
                  .to change(entity, :associations)
                  .to be >= { 'amplitude' => value }
              end
            end

            describe 'with key: an invalid Symbol' do
              it 'should force update the associations' do
                expect do
                  entity.write_association(:amplitude, value, safe: false)
                end
                  .to change(entity, :associations)
                  .to be >= { 'amplitude' => value }
              end
            end
          end
        end

        describe 'with safe: true' do
          describe 'with key: nil' do
            let(:error_message) { "association can't be blank" }

            it 'should raise an exception' do
              expect { entity.write_association(nil, nil, safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an Object' do
            let(:error_message) { 'association is not a String or a Symbol' }

            it 'should raise an exception' do
              expect do
                entity.write_association(Object.new.freeze, nil, safe: true)
              end
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an empty String' do
            let(:error_message) { "association can't be blank" }

            it 'should raise an exception' do
              expect { entity.write_association('', nil, safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an empty Symbol' do
            let(:error_message) { "association can't be blank" }

            it 'should raise an exception' do
              expect { entity.write_association(:'', nil, safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an invalid String' do
            let(:error_message) { 'unknown association "phase_angle"' }

            it 'should raise an exception' do
              expect do
                entity.write_association('phase_angle', nil, safe: true)
              end
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with key: an invalid Symbol' do
            let(:error_message) { 'unknown association :phase_angle' }

            it 'should raise an exception' do
              expect { entity.write_association(:phase_angle, nil, safe: true) }
                .to raise_error ArgumentError, error_message
            end
          end

          wrap_context 'when the entity class defines associations' do
            describe 'with key: an invalid String' do
              let(:error_message) { 'unknown association "phase_angle"' }

              it 'should raise an exception' do
                expect do
                  entity.write_association('phase_angle', nil, safe: true)
                end
                  .to raise_error ArgumentError, error_message
              end
            end

            describe 'with key: an invalid Symbol' do
              let(:error_message) { 'unknown association :phase_angle' }

              it 'should raise an exception' do
                expect do
                  entity.write_association(:phase_angle, nil, safe: true)
                end
                  .to raise_error ArgumentError, error_message
              end
            end

            describe 'with key: a valid String' do
              describe 'with nil' do
                it 'should not change the association' do
                  expect { entity.write_association('parent', nil, safe: true) }
                    .not_to change(entity, :parent)
                end
              end

              describe 'with a value' do
                let(:value) { Spec::Parent.new(name: 'new parent') }

                it 'should set the association' do
                  expect do
                    entity.write_association('parent', value, safe: true)
                  end
                    .to change(entity, :parent)
                    .to be == value
                end
              end
            end

            describe 'with key: a valid Symbol' do
              describe 'with nil' do
                it 'should not change the association' do
                  expect { entity.write_association(:parent, nil, safe: true) }
                    .not_to change(entity, :parent)
                end
              end

              describe 'with a value' do
                let(:value) { Spec::Parent.new(name: 'new parent') }

                it 'should set the association' do
                  expect do
                    entity.write_association(:parent, value, safe: true)
                  end
                    .to change(entity, :parent)
                    .to be == value
                end
              end
            end

            wrap_context 'when the entity has association values' do
              describe 'with key: a valid String' do
                describe 'with nil' do
                  it 'should clear the association' do
                    expect do
                      entity.write_association('parent', nil, safe: true)
                    end
                      .to change(entity, :parent)
                      .to be nil
                  end
                end

                describe 'with a value' do
                  let(:value) { Spec::Parent.new(name: 'new parent') }

                  it 'should set the association' do
                    expect do
                      entity.write_association('parent', value, safe: true)
                    end
                      .to change(entity, :parent)
                      .to be == value
                  end
                end
              end

              describe 'with key: a valid Symbol' do
                describe 'with nil' do
                  it 'should clear the association' do
                    expect do
                      entity.write_association(:parent, nil, safe: true)
                    end
                      .to change(entity, :parent)
                      .to be nil
                  end
                end

                describe 'with a value' do
                  let(:value) { Spec::Parent.new(name: 'new parent') }

                  it 'should set the association' do
                    expect do
                      entity.write_association(:parent, value, safe: true)
                    end
                      .to change(entity, :parent)
                      .to be == value
                  end
                end
              end
            end
          end

          wrap_context 'when the entity class defines properties' do
            describe 'with key: an invalid String' do
              let(:error_message) { 'unknown association "amplitude"' }

              it 'should raise an exception' do
                expect do
                  entity.write_association('amplitude', nil, safe: true)
                end
                  .to raise_error ArgumentError, error_message
              end
            end

            describe 'with key: an invalid Symbol' do
              let(:error_message) { 'unknown association :amplitude' }

              it 'should raise an exception' do
                expect do
                  entity.write_association(:amplitude, nil, safe: true)
                end
                  .to raise_error ArgumentError, error_message
              end
            end
          end
        end
      end
    end
  end
end
