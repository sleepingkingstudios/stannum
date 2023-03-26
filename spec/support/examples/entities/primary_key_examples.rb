# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples/entities'
require 'support/examples/entity_examples'

module Spec::Support::Examples::Entities
  module PrimaryKeyExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    include Spec::Support::Examples::EntityExamples

    shared_context 'when the entity class defines integer primary key' do
      let(:entity_class) do
        defined?(super()) ? super() : Spec::EntityClass
      end

      before(:example) do
        entity_class.instance_eval do
          define_primary_key :id, 'Integer'
        end
      end
    end

    shared_context 'when the entity class defines string primary key' do
      let(:entity_class) do
        defined?(super()) ? super() : Spec::EntityClass
      end

      before(:example) do
        entity_class.instance_eval do
          define_primary_key :uuid, 'String'
        end
      end
    end

    shared_context 'when the subclass defines primary key' do
      before(:example) do
        Spec::EntitySubclass.instance_eval do
          define_primary_key :id, 'Integer'
        end
      end
    end

    shared_examples 'should implement the PrimaryKey methods' do
      describe '::define_primary_key' do
        shared_examples 'should define the attribute' do
          let(:expected) do
            an_instance_of(Stannum::Attribute)
              .and(
                have_attributes(
                  name:    attr_name.to_s,
                  type:    attr_type.to_s,
                  options: { primary_key: true, required: true }.merge(options)
                )
              )
          end

          it 'should add the attribute to ::Attributes' do
            expect { define_primary_key }
              .to change { described_class.attributes.count }
              .by(1)
          end

          it 'should add the attribute key to ::Attributes' do
            expect { define_primary_key }
              .to change(described_class.attributes, :each_key)
              .to include(attr_name.to_s)
          end

          it 'should add the attribute value to ::Attributes' do
            expect { define_primary_key }
              .to change(described_class.attributes, :each_value)
              .to include(expected)
          end
        end

        let(:attr_name) { :id }
        let(:attr_type) { Integer }
        let(:options)   { {} }

        def define_primary_key
          described_class.define_primary_key(attr_name, attr_type, **options)
        end

        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:define_primary_key)
            .with(2).arguments
            .and_any_keywords
        end

        describe 'with attr_name: a String' do
          let(:attr_name) { 'id' }

          it 'should return the attribute name as a Symbol' do
            expect(define_primary_key).to be :id
          end

          include_examples 'should define the attribute'
        end

        describe 'with attr_name: a Symbol' do
          let(:attr_name) { :id }

          it 'should return the attribute name as a Symbol' do
            expect(define_primary_key).to be :id
          end

          include_examples 'should define the attribute'
        end

        describe 'with attr_type: String' do
          let(:attr_type) { String }

          include_examples 'should define the attribute'
        end

        describe 'with options: value' do
          let(:options) { { key: 'value' } }

          include_examples 'should define the attribute'
        end

        wrap_context 'when the entity class defines attributes' do
          include_examples 'should define the attribute'

          describe 'with options: value' do
            let(:options) { { key: 'value' } }

            include_examples 'should define the attribute'
          end
        end

        wrap_context 'when the entity class defines integer primary key' do
          let(:error_message) do
            %(#{described_class.name} already defines primary key "id")
          end

          it 'should raise an exception' do
            expect { define_primary_key }
              .to raise_error(
                Stannum::Entities::PrimaryKey::PrimaryKeyAlreadyExists,
                error_message
              )
          end
        end

        wrap_context 'when the entity class defines string primary key' do
          let(:error_message) do
            %(#{described_class.name} already defines primary key "uuid")
          end

          it 'should raise an exception' do
            expect { define_primary_key }
              .to raise_error(
                Stannum::Entities::PrimaryKey::PrimaryKeyAlreadyExists,
                error_message
              )
          end
        end

        wrap_context 'with an entity subclass' do
          include_examples 'should define the attribute'

          # rubocop:disable RSpec/RepeatedExampleGroupBody
          wrap_context 'when the entity class defines attributes' do
            include_examples 'should define the attribute'

            describe 'with options: value' do
              let(:options) { { key: 'value' } }

              include_examples 'should define the attribute'
            end
          end

          wrap_context 'when the subclass defines attributes' do
            include_examples 'should define the attribute'

            describe 'with options: value' do
              let(:options) { { key: 'value' } }

              include_examples 'should define the attribute'
            end
          end

          wrap_context 'when the entity class defines integer primary key' do
            let(:error_message) do
              %(#{described_class.name} already defines primary key "id")
            end

            it 'should raise an exception' do
              expect { define_primary_key }
                .to raise_error(
                  Stannum::Entities::PrimaryKey::PrimaryKeyAlreadyExists,
                  error_message
                )
            end
          end

          wrap_context 'when the entity class defines string primary key' do
            let(:error_message) do
              %(#{described_class.name} already defines primary key "uuid")
            end

            it 'should raise an exception' do
              expect { define_primary_key }
                .to raise_error(
                  Stannum::Entities::PrimaryKey::PrimaryKeyAlreadyExists,
                  error_message
                )
            end
          end

          wrap_context 'when the subclass defines primary key' do
            let(:error_message) do
              %(#{described_class.name} already defines primary key "id")
            end

            it 'should raise an exception' do
              expect { define_primary_key }
                .to raise_error(
                  Stannum::Entities::PrimaryKey::PrimaryKeyAlreadyExists,
                  error_message
                )
            end
          end
          # rubocop:enable RSpec/RepeatedExampleGroupBody
        end
      end

      describe '::primary_key' do
        let(:error_message) do
          "#{described_class.name} does not define a primary key"
        end

        include_examples 'should define class reader', :primary_key

        it 'should raise an exception' do
          expect { described_class.primary_key }
            .to raise_error(
              Stannum::Entities::PrimaryKey::PrimaryKeyMissing,
              error_message
            )
        end

        # rubocop:disable RSpec/RepeatedExampleGroupBody
        wrap_context 'when the entity class defines integer primary key' do
          let(:expected) do
            described_class
              .attributes
              .find { |_, attr| attr.primary_key? }
              .last
          end

          it { expect(described_class.primary_key).to be == expected }
        end

        wrap_context 'when the entity class defines string primary key' do
          let(:expected) do
            described_class
              .attributes
              .find { |_, attr| attr.primary_key? }
              .last
          end

          it { expect(described_class.primary_key).to be == expected }
        end
        # rubocop:enable RSpec/RepeatedExampleGroupBody

        wrap_context 'with an entity subclass' do
          it 'should raise an exception' do
            expect { described_class.primary_key }
              .to raise_error(
                Stannum::Entities::PrimaryKey::PrimaryKeyMissing,
                error_message
              )
          end

          # rubocop:disable RSpec/RepeatedExampleGroupBody
          wrap_context 'when the entity class defines integer primary key' do
            let(:expected) do
              described_class
                .attributes
                .find { |_, attr| attr.primary_key? }
                .last
            end

            it { expect(described_class.primary_key).to be == expected }
          end

          wrap_context 'when the entity class defines string primary key' do
            let(:expected) do
              described_class
                .attributes
                .find { |_, attr| attr.primary_key? }
                .last
            end

            it { expect(described_class.primary_key).to be == expected }
          end

          wrap_context 'when the subclass defines primary key' do
            let(:expected) do
              described_class
                .attributes
                .find { |_, attr| attr.primary_key? }
                .last
            end

            it { expect(described_class.primary_key).to be == expected }
          end
          # rubocop:enable RSpec/RepeatedExampleGroupBody
        end
      end

      describe '::primary_key?' do
        it 'should define the class method' do
          expect(described_class).to respond_to(:primary_key?).with(0).arguments
        end

        wrap_context 'when the entity class defines attributes' do
          it { expect(described_class.primary_key?).to be false }
        end

        # rubocop:disable RSpec/RepeatedExampleGroupBody
        wrap_context 'when the entity class defines integer primary key' do
          it { expect(described_class.primary_key?).to be true }
        end

        wrap_context 'when the entity class defines string primary key' do
          it { expect(described_class.primary_key?).to be true }
        end
        # rubocop:enable RSpec/RepeatedExampleGroupBody

        wrap_context 'with an entity subclass' do
          it { expect(described_class.primary_key?).to be false }

          # rubocop:disable RSpec/RepeatedExampleGroupBody
          wrap_context 'when the entity class defines integer primary key' do
            it { expect(described_class.primary_key?).to be true }
          end

          wrap_context 'when the entity class defines string primary key' do
            it { expect(described_class.primary_key?).to be true }
          end

          wrap_context 'when the subclass defines primary key' do
            it { expect(described_class.primary_key?).to be true }
          end
          # rubocop:enable RSpec/RepeatedExampleGroupBody
        end
      end

      describe '::primary_key_name' do
        include_examples 'should define class reader', :primary_key_name, nil

        wrap_context 'when the entity class defines attributes' do
          it { expect(described_class.primary_key_name).to be nil }
        end

        wrap_context 'when the entity class defines integer primary key' do
          it { expect(described_class.primary_key_name).to be == 'id' }
        end

        wrap_context 'when the entity class defines string primary key' do
          it { expect(described_class.primary_key_name).to be == 'uuid' }
        end

        wrap_context 'with an entity subclass' do
          it { expect(described_class.primary_key_name).to be nil }

          # rubocop:disable RSpec/RepeatedExampleGroupBody
          wrap_context 'when the entity class defines integer primary key' do
            it { expect(described_class.primary_key_name).to be == 'id' }
          end

          wrap_context 'when the entity class defines string primary key' do
            it { expect(described_class.primary_key_name).to be == 'uuid' }
          end

          wrap_context 'when the subclass defines primary key' do
            it { expect(described_class.primary_key_name).to be == 'id' }
          end
          # rubocop:enable RSpec/RepeatedExampleGroupBody
        end
      end

      describe '#primary_key?' do
        include_examples 'should define predicate', :primary_key?, false

        wrap_context 'when the entity class defines attributes' do
          it { expect(described_class.primary_key?).to be false }
        end

        wrap_context 'when the entity class defines integer primary key' do
          it { expect(entity.primary_key?).to be false }

          context 'when the entity has a primary key value' do
            let(:properties) { super().merge(id: 0) }

            it { expect(entity.primary_key?).to be true }
          end
        end

        wrap_context 'when the entity class defines string primary key' do
          it { expect(entity.primary_key?).to be false }

          context 'when the entity has an empty primary key value' do
            let(:properties) { super().merge(uuid: '') }

            it { expect(entity.primary_key?).to be false }
          end

          context 'when the entity has a non-empty primary key value' do
            let(:uuid)       { '00000000-0000-0000-0000-000000000000' }
            let(:properties) { super().merge(uuid: uuid) }

            it { expect(entity.primary_key?).to be true }
          end
        end

        wrap_context 'with an entity subclass' do
          it { expect(entity.primary_key?).to be false }

          # rubocop:disable RSpec/RepeatedExampleGroupBody
          wrap_context 'when the entity class defines integer primary key' do
            it { expect(entity.primary_key?).to be false }

            context 'when the entity has a primary key value' do
              let(:properties) { super().merge(id: 0) }

              it { expect(entity.primary_key?).to be true }
            end
          end

          wrap_context 'when the entity class defines string primary key' do
            it { expect(entity.primary_key?).to be false }

            context 'when the entity has an empty primary key value' do
              let(:properties) { super().merge(uuid: '') }

              it { expect(entity.primary_key?).to be false }
            end

            context 'when the entity has a non-empty primary key value' do
              let(:properties) do
                super().merge(uuid: '00000000-0000-0000-0000-000000000000')
              end

              it { expect(entity.primary_key?).to be true }
            end
          end

          wrap_context 'when the subclass defines primary key' do
            it { expect(entity.primary_key?).to be false }

            context 'when the entity has a primary key value' do
              let(:properties) { super().merge(id: 0) }

              it { expect(entity.primary_key?).to be true }
            end
          end
          # rubocop:enable RSpec/RepeatedExampleGroupBody
        end
      end

      describe '#primary_key_value' do
        let(:error_message) do
          "#{described_class.name} does not define a primary key"
        end

        include_examples 'should define reader', :primary_key_value

        it 'should alias the method' do
          expect(entity)
            .to have_aliased_method(:primary_key_value)
            .as(:primary_key)
        end

        it 'should raise an exception' do
          expect { entity.primary_key_value }
            .to raise_error(
              Stannum::Entities::PrimaryKey::PrimaryKeyMissing,
              error_message
            )
        end

        wrap_context 'when the entity class defines attributes' do
          it 'should raise an exception' do
            expect { entity.primary_key_value }
              .to raise_error(
                Stannum::Entities::PrimaryKey::PrimaryKeyMissing,
                error_message
              )
          end
        end

        wrap_context 'when the entity class defines integer primary key' do
          it { expect(entity.primary_key_value).to be nil }

          context 'when the entity has a primary key value' do
            let(:properties) { super().merge(id: 0) }

            it { expect(entity.primary_key_value).to be 0 }
          end
        end

        wrap_context 'when the entity class defines string primary key' do
          it { expect(entity.primary_key_value).to be nil }

          context 'when the entity has an empty primary key value' do
            let(:properties) { super().merge(uuid: '') }

            it { expect(entity.primary_key_value).to be == '' }
          end

          context 'when the entity has a non-empty primary key value' do
            let(:uuid)       { '00000000-0000-0000-0000-000000000000' }
            let(:properties) { super().merge(uuid: uuid) }

            it { expect(entity.primary_key_value).to be == uuid }
          end
        end

        wrap_context 'with an entity subclass' do
          it 'should raise an exception' do
            expect { entity.primary_key_value }
              .to raise_error(
                Stannum::Entities::PrimaryKey::PrimaryKeyMissing,
                error_message
              )
          end

          wrap_context 'when the entity class defines attributes' do
            it 'should raise an exception' do
              expect { entity.primary_key_value }
                .to raise_error(
                  Stannum::Entities::PrimaryKey::PrimaryKeyMissing,
                  error_message
                )
            end
          end

          # rubocop:disable RSpec/RepeatedExampleGroupBody
          wrap_context 'when the entity class defines integer primary key' do
            it { expect(entity.primary_key_value).to be nil }

            context 'when the entity has a primary key value' do
              let(:properties) { super().merge(id: 0) }

              it { expect(entity.primary_key_value).to be 0 }
            end
          end

          wrap_context 'when the entity class defines string primary key' do
            it { expect(entity.primary_key_value).to be nil }

            context 'when the entity has an empty primary key value' do
              let(:properties) { super().merge(uuid: '') }

              it { expect(entity.primary_key_value).to be == '' }
            end

            context 'when the entity has a non-empty primary key value' do
              let(:uuid)       { '00000000-0000-0000-0000-000000000000' }
              let(:properties) { super().merge(uuid: uuid) }

              it { expect(entity.primary_key_value).to be == uuid }
            end
          end

          wrap_context 'when the subclass defines primary key' do
            it { expect(entity.primary_key_value).to be nil }

            context 'when the entity has a primary key value' do
              let(:properties) { super().merge(id: 0) }

              it { expect(entity.primary_key_value).to be 0 }
            end
          end
          # rubocop:enable RSpec/RepeatedExampleGroupBody
        end
      end
    end
  end
end
