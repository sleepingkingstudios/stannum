# frozen_string_literal: true

require 'bigdecimal'

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'stannum/rspec/match_errors'

require 'support/examples/entities'
require 'support/examples/entities/attributes_examples'
require 'support/examples/entity_examples'

module Spec::Support::Examples::Entities
  module ConstraintsExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    include Stannum::RSpec::Matchers
    include Spec::Support::Examples::Entities::AttributesExamples
    include Spec::Support::Examples::EntityExamples

    shared_context 'when the entity class defines constraints' do
      include_context 'when the entity class defines attributes'

      before(:example) do
        entity_class.instance_eval do
          constraint :name, Stannum::Constraints::Presence.new
          constraint(:quantity) { |quantity| quantity >= 0 }
          constraint { |struct| !struct.description&.empty? }
        end
      end
    end

    shared_context 'when the subclass defines constraints' do
      before(:example) do
        described_class.instance_eval do
          constraint(:size) do |size|
            # :nocov:
            %w[Tiny Small Medium Large Huge Gargantuan Colossal].include?(size)
            # :nocov:
          end
        end
      end
    end

    shared_examples 'should implement the Constraints methods' do
      describe '::Contract' do
        shared_examples 'should not match the entity' do
          it { expect(described_class::Contract.matches?(entity)).to be false }

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(entity))
              .to match_errors(expected_errors)
          end
        end

        shared_examples 'should match the entity' do
          it { expect(described_class::Contract.matches?(entity)).to be true }

          it 'should not have any errors' do
            expect(described_class::Contract.errors_for(entity)).to be == []
          end
        end

        let(:constraints) do
          described_class::Contract.send(:each_constraint).to_a
        end

        it { expect(described_class).to define_constant(:Contract) }

        it { expect(described_class::Contract).to be_a(Stannum::Contract) }

        it { expect(constraints.size).to be 0 }

        describe 'with an empty entity' do
          include_examples 'should match the entity'
        end

        wrap_context 'when the entity class defines attributes' do
          it { expect(constraints.size).to be 3 }

          describe 'with an empty entity' do
            let(:expected_errors) do
              [
                {
                  data:    { required: true, type: String },
                  message: nil,
                  path:    [:name],
                  type:    'stannum.constraints.is_not_type'
                }
              ]
            end

            include_examples 'should not match the entity'
          end

          describe 'with a non-matching entity' do
            let(:properties) do
              {
                description: :invalid,
                name:        'Self-sealing Stem Bolt'
              }
            end
            let(:expected_errors) do
              [
                {
                  data:    { required: false, type: String },
                  message: nil,
                  path:    [:description],
                  type:    'stannum.constraints.is_not_type'
                }
              ]
            end

            include_examples 'should not match the entity'
          end

          describe 'with a matching entity' do
            let(:properties) do
              {
                name:        'Self-sealing Stem Bolt',
                description: 'No one is quite sure what this thing is.'
              }
            end

            include_examples 'should match the entity'
          end
        end

        wrap_context 'when the entity class defines constraints' do
          it { expect(constraints.size).to be 6 }

          describe 'with an empty entity' do
            let(:expected_errors) do
              [
                {
                  data:    { required: true, type: String },
                  message: nil,
                  path:    [:name],
                  type:    'stannum.constraints.is_not_type'
                },
                {
                  data:    {},
                  message: nil,
                  path:    [:name],
                  type:    'stannum.constraints.absent'
                }
              ]
            end

            include_examples 'should not match the entity'
          end

          describe 'with a non-matching entity' do
            let(:properties) do
              {
                description: :invalid,
                name:        'Self-sealing Stem Bolt',
                quantity:    -1
              }
            end
            let(:expected_errors) do
              [
                {
                  data:    { required: false, type: String },
                  message: nil,
                  path:    [:description],
                  type:    'stannum.constraints.is_not_type'
                },
                {
                  data:    {},
                  message: nil,
                  path:    [:quantity],
                  type:    'stannum.constraints.invalid'
                }
              ]
            end

            include_examples 'should not match the entity'
          end

          describe 'with a matching entity' do
            let(:properties) do
              {
                name:        'Self-sealing Stem Bolt',
                description: 'No one is quite sure what this thing is.'
              }
            end

            include_examples 'should match the entity'
          end
        end

        wrap_context 'with an abstract entity class' do
          let(:abstract_constraints) do
            abstract_class::Contract.send(:each_constraint).to_a
          end

          it { expect(abstract_class).to define_constant(:Contract) }

          it { expect(abstract_class::Contract).to be_a(Stannum::Contract) }

          it { expect(abstract_constraints.size).to be 0 }

          it { expect(described_class).to define_constant(:Contract) }

          it { expect(described_class::Contract).to be_a(Stannum::Contract) }

          it { expect(constraints.size).to be 0 }

          wrap_context 'when the entity class defines attributes' do
            it { expect(abstract_constraints.size).to be 0 }

            it { expect(constraints.size).to be 3 }
          end

          wrap_context 'when the entity class defines constraints' do
            it { expect(abstract_constraints.size).to be 0 }

            it { expect(constraints.size).to be 6 }
          end
        end

        wrap_context 'with an abstract entity module' do
          it { expect(described_class).to define_constant(:Contract) }

          it { expect(described_class::Contract).to be_a(Stannum::Contract) }

          it { expect(constraints.size).to be 0 }

          wrap_context 'when the entity class defines attributes' do
            it { expect(constraints.size).to be 3 }
          end

          wrap_context 'when the entity class defines constraints' do
            it { expect(constraints.size).to be 6 }
          end
        end

        wrap_context 'with an entity subclass' do
          let(:superclass_constraints) do
            entity_superclass::Contract.send(:each_constraint).to_a
          end

          it { expect(entity_superclass).to define_constant(:Contract) }

          it { expect(entity_superclass::Contract).to be_a(Stannum::Contract) }

          it { expect(superclass_constraints.size).to be 0 }

          it { expect(described_class).to define_constant(:Contract) }

          it { expect(described_class::Contract).to be_a(Stannum::Contract) }

          it { expect(constraints.size).to be 0 }

          wrap_context 'when the entity class defines attributes' do
            it { expect(superclass_constraints.size).to be 3 }

            it { expect(constraints.size).to be 3 }

            wrap_context 'when the subclass defines attributes' do
              it { expect(superclass_constraints.size).to be 3 }

              it { expect(constraints.size).to be 4 }
            end
          end

          wrap_context 'when the entity class defines constraints' do
            it { expect(superclass_constraints.size).to be 6 }

            it { expect(constraints.size).to be 6 }

            wrap_context 'when the subclass defines constraints' do
              it { expect(superclass_constraints.size).to be 6 }

              it { expect(constraints.size).to be 7 }
            end
          end
        end
      end

      describe '.attribute' do
        let(:attr_name) { :price }
        let(:attr_type) { BigDecimal }
        let(:options)   { {} }

        def constraints
          described_class::Contract.send(:each_constraint).to_a
        end

        describe 'with attr_name: a String' do
          let(:attr_name)  { 'price' }
          let(:constraint) { constraints.last.constraint }

          it 'should add a constraint to the contract' do
            expect do
              described_class.attribute(attr_name, attr_type, **options)
            end
              .to change { constraints.size } # rubocop:disable RSpec/ExpectChange
              .by(1)
          end

          it 'should create an attribute constraint', :aggregate_failures do
            described_class.attribute(attr_name, attr_type, **options)

            expect(constraint).to be_a(Stannum::Constraints::Type)
            expect(constraint.expected_type).to be attr_type
            expect(constraint.required?).to be true
          end

          describe 'with optional: false' do
            let(:options) { super().merge(optional: false) }

            it 'should create an attribute constraint', :aggregate_failures do
              described_class.attribute(attr_name, attr_type, **options)

              expect(constraint).to be_a(Stannum::Constraints::Type)
              expect(constraint.expected_type).to be attr_type
              expect(constraint.required?).to be true
            end
          end

          describe 'with optional: true' do
            let(:options) { super().merge(optional: true) }

            it 'should create an attribute constraint', :aggregate_failures do
              described_class.attribute(attr_name, attr_type, **options)

              expect(constraint).to be_a(Stannum::Constraints::Type)
              expect(constraint.expected_type).to be attr_type
              expect(constraint.required?).to be false
            end
          end

          describe 'with required: false' do
            let(:options) { super().merge(required: false) }

            it 'should create an attribute constraint', :aggregate_failures do
              described_class.attribute(attr_name, attr_type, **options)

              expect(constraint).to be_a(Stannum::Constraints::Type)
              expect(constraint.expected_type).to be attr_type
              expect(constraint.required?).to be false
            end
          end

          describe 'with required: true' do
            let(:options) { super().merge(required: true) }

            it 'should create an attribute constraint', :aggregate_failures do
              described_class.attribute(attr_name, attr_type, **options)

              expect(constraint).to be_a(Stannum::Constraints::Type)
              expect(constraint.expected_type).to be attr_type
              expect(constraint.required?).to be true
            end
          end
        end

        describe 'with attr_name: a Symbol' do
          let(:attr_name)  { :price }
          let(:constraint) { constraints.last.constraint }

          it 'should add a constraint to the contract' do
            expect do
              described_class.attribute(attr_name, attr_type, **options)
            end
              .to change { constraints.size } # rubocop:disable RSpec/ExpectChange
              .by(1)
          end

          it 'should create an attribute constraint', :aggregate_failures do
            described_class.attribute(attr_name, attr_type, **options)

            expect(constraint).to be_a(Stannum::Constraints::Type)
            expect(constraint.expected_type).to be attr_type
            expect(constraint.required?).to be true
          end

          describe 'with optional: false' do
            let(:options) { super().merge(optional: false) }

            it 'should create an attribute constraint', :aggregate_failures do
              described_class.attribute(attr_name, attr_type, **options)

              expect(constraint).to be_a(Stannum::Constraints::Type)
              expect(constraint.expected_type).to be attr_type
              expect(constraint.required?).to be true
            end
          end

          describe 'with optional: true' do
            let(:options) { super().merge(optional: true) }

            it 'should create an attribute constraint', :aggregate_failures do
              described_class.attribute(attr_name, attr_type, **options)

              expect(constraint).to be_a(Stannum::Constraints::Type)
              expect(constraint.expected_type).to be attr_type
              expect(constraint.required?).to be false
            end
          end

          describe 'with required: false' do
            let(:options) { super().merge(required: false) }

            it 'should create an attribute constraint', :aggregate_failures do
              described_class.attribute(attr_name, attr_type, **options)

              expect(constraint).to be_a(Stannum::Constraints::Type)
              expect(constraint.expected_type).to be attr_type
              expect(constraint.required?).to be false
            end
          end

          describe 'with required: true' do
            let(:options) { super().merge(required: true) }

            it 'should create an attribute constraint', :aggregate_failures do
              described_class.attribute(attr_name, attr_type, **options)

              expect(constraint).to be_a(Stannum::Constraints::Type)
              expect(constraint.expected_type).to be attr_type
              expect(constraint.required?).to be true
            end
          end
        end
      end

      describe '.constraint' do
        let(:constraint) { Stannum::Constraint.new { nil } }

        def constraints
          described_class::Contract.send(:each_constraint).to_a
        end

        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:constraint)
            .with(0..2).arguments
            .and_a_block
        end

        describe 'with attribute name: an Object' do
          let(:error_message) do
            'attribute is not a String or a Symbol'
          end

          it 'should raise an error' do
            expect { described_class.constraint(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with attribute name: an empty String' do
          it 'should raise an error' do
            expect { described_class.constraint('') }
              .to raise_error ArgumentError, "attribute can't be blank"
          end
        end

        describe 'with attribute name: an empty Symbol' do
          it 'should raise an error' do
            expect { described_class.constraint(:'') }
              .to raise_error ArgumentError, "attribute can't be blank"
          end
        end

        describe 'with constraint: not given' do
          it 'should raise an error' do
            expect { described_class.constraint('name') }
              .to raise_error ArgumentError, "constraint can't be blank"
          end
        end

        describe 'with constraint: nil' do
          it 'should raise an error' do
            expect { described_class.constraint('name', nil) }
              .to raise_error ArgumentError, "constraint can't be blank"
          end
        end

        describe 'with constraint: an Object' do
          it 'should raise an error' do
            expect { described_class.constraint('name', Object.new.freeze) }
              .to raise_error ArgumentError,
                'constraint must be a Stannum::Constraints::Base'
          end
        end

        describe 'with a block' do
          it 'should add the constraint to the contract' do
            expect { described_class.constraint { nil } }
              .to change { constraints.size } # rubocop:disable RSpec/ExpectChange
              .by(1)
          end

          it 'should create an anonymous constraint' do
            expect do |block|
              described_class.constraint(&block)

              constraint = constraints.last.constraint

              constraint.matches?(entity)
            end
              .to yield_with_args(entity)
          end
        end

        describe 'with attribute name: a String and a block' do
          let(:value) { 'Self-sealing Stem Bolt' }

          it 'should add the constraint to the contract' do
            expect { described_class.constraint('name') { nil } }
              .to change { constraints.size } # rubocop:disable RSpec/ExpectChange
              .by(1)
          end

          it 'should create an anonymous constraint' do
            expect do |block|
              described_class.constraint('name', &block)

              constraint = constraints.last.constraint

              constraint.matches?(value)
            end
              .to yield_with_args(value)
          end
        end

        describe 'with attribute name: a Symbol and a block' do
          let(:value) { 'Self-sealing Stem Bolt' }

          it 'should add the constraint to the contract' do
            expect { described_class.constraint(:name) { nil } }
              .to change { constraints.size } # rubocop:disable RSpec/ExpectChange
              .by(1)
          end

          it 'should create an anonymous constraint' do
            expect do |block|
              described_class.constraint(:name, &block)

              constraint = constraints.last.constraint

              constraint.matches?(value)
            end
              .to yield_with_args(value)
          end
        end

        describe 'with attribute name: a String and constraint: a constraint' do
          it 'should add the constraint to the contract' do
            expect { described_class.constraint('name', constraint) }
              .to change { constraints }
              .to include(
                have_attributes(
                  constraint:,
                  property:   :name
                )
              )
          end
        end

        describe 'with attribute name: a Symbol and constraint: a constraint' do
          it 'should add the constraint to the contract' do
            expect { described_class.constraint(:name, constraint) }
              .to change { constraints }
              .to include(
                have_attributes(
                  constraint:,
                  property:   :name
                )
              )
          end
        end

        describe 'with constraint: a constraint' do
          it 'should add the constraint to the contract' do
            expect { described_class.constraint(constraint) }
              .to change { constraints }
              .to include(
                have_attributes(
                  constraint:,
                  property:   nil
                )
              )
          end
        end
      end

      describe '.contract' do
        let(:constraints) do
          described_class.contract.send(:each_constraint).to_a
        end

        it { expect(described_class).to define_reader(:contract) }

        it { expect(described_class.contract).to be(described_class::Contract) }

        it { expect(constraints.size).to be 0 }

        wrap_context 'when the entity class defines attributes' do
          it { expect(constraints.size).to be 3 }
        end

        wrap_context 'when the entity class defines constraints' do
          it { expect(constraints.size).to be 6 }
        end

        wrap_context 'with an abstract entity class' do
          let(:abstract_constraints) do
            abstract_class::Contract.send(:each_constraint).to_a
          end

          it { expect(abstract_constraints.size).to be 0 }

          it { expect(constraints.size).to be 0 }

          wrap_context 'when the entity class defines attributes' do
            it { expect(abstract_constraints.size).to be 0 }

            it { expect(constraints.size).to be 3 }
          end

          wrap_context 'when the entity class defines constraints' do
            it { expect(abstract_constraints.size).to be 0 }

            it { expect(constraints.size).to be 6 }
          end
        end

        wrap_context 'with an abstract entity module' do
          it { expect(constraints.size).to be 0 }

          wrap_context 'when the entity class defines attributes' do
            it { expect(constraints.size).to be 3 }
          end

          wrap_context 'when the entity class defines constraints' do
            it { expect(constraints.size).to be 6 }
          end
        end

        wrap_context 'with an entity subclass' do
          let(:superclass_constraints) do
            entity_superclass::Contract.send(:each_constraint).to_a
          end

          it { expect(superclass_constraints.size).to be 0 }

          it { expect(constraints.size).to be 0 }

          wrap_context 'when the entity class defines attributes' do
            it { expect(superclass_constraints.size).to be 3 }

            it { expect(constraints.size).to be 3 }

            wrap_context 'when the subclass defines attributes' do
              it { expect(superclass_constraints.size).to be 3 }

              it { expect(constraints.size).to be 4 }
            end
          end

          wrap_context 'when the entity class defines constraints' do
            it { expect(superclass_constraints.size).to be 6 }

            it { expect(constraints.size).to be 6 }

            wrap_context 'when the subclass defines constraints' do
              it { expect(superclass_constraints.size).to be 6 }

              it { expect(constraints.size).to be 7 }
            end
          end
        end
      end
    end
  end
end
