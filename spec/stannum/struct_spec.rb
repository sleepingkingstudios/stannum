# frozen_string_literal: true

require 'bigdecimal'

require 'stannum/struct'

RSpec.describe Stannum::Struct do
  shared_context 'when the struct defines attributes' do
    before(:example) do
      Spec::CustomStruct.instance_eval do
        attribute :name,        'String'
        attribute :description, 'String',  optional: true
        attribute :quantity,    'Integer', default:  0
      end
    end
  end

  shared_context 'when the struct defines constraints' do
    include_context 'when the struct defines attributes'

    before(:example) do
      Spec::CustomStruct.instance_eval do
        constraint :name, Stannum::Constraints::Presence.new
        constraint(:quantity) { |quantity| quantity >= 0 }
        constraint { |struct| !struct.description&.empty? }
      end
    end
  end

  shared_context 'when the struct has attribute values' do
    include_context 'when the struct defines attributes'

    let(:attributes) do
      {
        'description' => 'No one is quite sure what this thing is.',
        'name'        => 'Self-sealing Stem Bolt',
        'quantity'    => 1_000
      }
    end
  end

  shared_context 'with a struct subclass' do
    let(:described_class) { Spec::SubclassStruct }

    example_class 'Spec::SubclassStruct', 'Spec::CustomStruct'
  end

  shared_context 'when the subclass defines attributes' do
    before(:example) do
      Spec::SubclassStruct.instance_eval do
        attribute :size, 'String'
      end
    end
  end

  shared_context 'when the subclass defines constraints' do
    include_context 'when the subclass defines attributes'

    before(:example) do
      Spec::SubclassStruct.instance_eval do
        constraint(:size) do |size|
          %w[Tiny Small Medium Large Huge Gargantuan Colossal].include?(size)
        end
      end
    end
  end

  shared_context 'when the subclass has attribute values' do
    include_context 'when the subclass defines attributes'

    before(:example) { attributes['size'] = 'Large' }
  end

  let(:described_class) { Spec::CustomStruct }
  let(:attributes)      { {} }
  let(:struct)          { described_class.new(attributes) }

  example_class 'Spec::CustomStruct' do |klass|
    klass.include Stannum::Struct # rubocop:disable RSpec/DescribedClass
  end

  def tools
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  describe '::Attributes' do
    let(:attributes) { described_class::Attributes }

    it { expect(described_class).to define_constant(:Attributes) }

    it { expect(attributes).to be_a Stannum::Schema }

    it { expect(described_class.ancestors).to include attributes }

    it { expect(attributes.each.size).to be 0 }

    wrap_context 'when the struct defines attributes' do
      it { expect(attributes.each.size).to be 3 }
    end

    wrap_context 'with a struct subclass' do
      let(:attributes) { described_class::Attributes }

      it { expect(described_class).to define_constant(:Attributes) }

      it { expect(attributes).to be_a Stannum::Schema }

      it { expect(attributes).not_to be described_class.superclass::Attributes }

      wrap_context 'when the struct defines attributes' do
        it { expect(attributes.each.size).to be 3 }
      end

      wrap_context 'when the subclass defines attributes' do
        it { expect(attributes.each.size).to be 1 }
      end

      context 'when the struct and the subclass define attributes' do
        include_context 'when the struct defines attributes'
        include_context 'when the subclass defines attributes'

        it { expect(attributes.each.size).to be 4 }

        it 'should include the struct attributes' do
          %i[name description quantity].each do |attr_name|
            expect(attributes[attr_name])
              .to be Spec::CustomStruct::Attributes[attr_name]
          end
        end

        it 'should include the subclass attributes' do
          %i[size].each do |attr_name|
            expect(attributes[attr_name])
              .to be described_class::Attributes[attr_name]
          end
        end
      end

      context 'when the struct has multiple ancestors with attributes' do
        include_context 'when the struct defines attributes'
        include_context 'when the subclass defines attributes'

        let(:described_class) { Spec::DescendantStruct }

        example_class 'Spec::DescendantStruct', 'Spec::SubclassStruct'

        before(:example) do
          Spec::DescendantStruct.instance_eval do
            attribute :price, 'BigDecimal'
          end
        end

        it { expect(attributes.each.size).to be 5 }

        it 'should include the struct attributes' do
          %i[name description quantity].each do |attr_name|
            expect(attributes[attr_name])
              .to be Spec::CustomStruct::Attributes[attr_name]
          end
        end

        it 'should include the subclass attributes' do
          %i[size].each do |attr_name|
            expect(attributes[attr_name])
              .to be Spec::SubclassStruct::Attributes[attr_name]
          end
        end

        it 'should include the descendant attributes' do
          %i[price].each do |attr_name|
            expect(attributes[attr_name])
              .to be described_class::Attributes[attr_name]
          end
        end
      end
    end
  end

  describe '::Contract' do
    let(:constraints) { described_class::Contract.send(:each_constraint).to_a }

    it { expect(described_class).to define_constant(:Contract) }

    it 'should be a contract instance' do
      expect(described_class::Contract).to be_a(Stannum::Contract)
    end

    it { expect(constraints.size).to be 0 }

    describe 'with an empty struct' do
      it { expect(described_class::Contract.errors_for(struct)).to be == [] }

      it { expect(described_class::Contract.matches?(struct)).to be true }
    end

    wrap_context 'when the struct defines attributes' do
      it { expect(constraints.size).to be 3 }

      describe 'with an empty struct' do
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

        it 'should return the errors' do
          expect(described_class::Contract.errors_for(struct))
            .to be == expected_errors
        end

        it { expect(described_class::Contract.matches?(struct)).to be false }
      end

      describe 'with a non-matching struct' do
        let(:attributes) do
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

        it 'should return the errors' do
          expect(described_class::Contract.errors_for(struct))
            .to be == expected_errors
        end

        it { expect(described_class::Contract.matches?(struct)).to be false }
      end

      describe 'with a matching struct' do
        let(:attributes) do
          {
            'name'        => 'Self-sealing Stem Bolt',
            'description' => 'No one is quite sure what this thing is.'
          }
        end

        it { expect(described_class::Contract.errors_for(struct)).to be == [] }

        it { expect(described_class::Contract.matches?(struct)).to be true }
      end
    end

    wrap_context 'when the struct defines constraints' do
      it { expect(constraints.size).to be 6 }

      describe 'with an empty struct' do
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

        it 'should return the errors' do
          expect(described_class::Contract.errors_for(struct).to_a)
            .to deep_match expected_errors.to_a
        end

        it { expect(described_class::Contract.matches?(struct)).to be false }
      end

      describe 'with a non-matching struct' do
        let(:attributes) do
          {
            name:        '',
            description: :invalid,
            quantity:    -10
          }
        end
        let(:expected_errors) do
          [
            {
              data:    {},
              message: nil,
              path:    [:name],
              type:    'stannum.constraints.absent'
            },
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

        it 'should return the errors' do
          expect(described_class::Contract.errors_for(struct))
            .to be == expected_errors
        end

        it { expect(described_class::Contract.matches?(struct)).to be false }
      end

      describe 'with a matching struct' do
        let(:attributes) do
          {
            name:        'Self-sealing Stem Bolt',
            description: 'No one is quite sure what this thing is.',
            quantity:    1_000
          }
        end

        it { expect(described_class::Contract.errors_for(struct)).to be == [] }

        it { expect(described_class::Contract.matches?(struct)).to be true }
      end
    end

    wrap_context 'with a struct subclass' do
      it { expect(constraints.size).to be 0 }

      describe 'with an empty struct' do
        it { expect(described_class::Contract.errors_for(struct)).to be == [] }

        it { expect(described_class::Contract.matches?(struct)).to be true }
      end

      wrap_context 'when the struct defines attributes' do
        it { expect(constraints.size).to be 3 }

        describe 'with an empty struct' do
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

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(struct))
              .to be == expected_errors
          end

          it { expect(described_class::Contract.matches?(struct)).to be false }
        end

        describe 'with a non-matching struct' do
          let(:attributes) do
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

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(struct))
              .to be == expected_errors
          end

          it { expect(described_class::Contract.matches?(struct)).to be false }
        end

        describe 'with a matching struct' do
          let(:attributes) do
            {
              'name'        => 'Self-sealing Stem Bolt',
              'description' => 'No one is quite sure what this thing is.'
            }
          end

          it 'should not have any errors' do
            expect(described_class::Contract.errors_for(struct)).to be == []
          end

          it { expect(described_class::Contract.matches?(struct)).to be true }
        end
      end

      wrap_context 'when the struct defines constraints' do
        it { expect(constraints.size).to be 6 }

        describe 'with an empty struct' do
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

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(struct))
              .to be == expected_errors
          end

          it { expect(described_class::Contract.matches?(struct)).to be false }
        end

        describe 'with a non-matching struct' do
          let(:attributes) do
            {
              name:        '',
              description: :invalid,
              quantity:    -10
            }
          end
          let(:expected_errors) do
            [
              {
                data:    {},
                message: nil,
                path:    [:name],
                type:    'stannum.constraints.absent'
              },
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

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(struct))
              .to be == expected_errors
          end

          it { expect(described_class::Contract.matches?(struct)).to be false }
        end

        describe 'with a matching struct' do
          let(:attributes) do
            {
              name:        'Self-sealing Stem Bolt',
              description: 'No one is quite sure what this thing is.',
              quantity:    1_000
            }
          end

          it 'should not have any errors' do
            expect(described_class::Contract.errors_for(struct)).to be == []
          end

          it { expect(described_class::Contract.matches?(struct)).to be true }
        end
      end

      wrap_context 'when the subclass defines attributes' do
        it { expect(constraints.size).to be 1 }

        describe 'with an empty struct' do
          let(:expected_errors) do
            [
              {
                data:    { required: true, type: String },
                message: nil,
                path:    [:size],
                type:    'stannum.constraints.is_not_type'
              }
            ]
          end

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(struct))
              .to be == expected_errors
          end

          it { expect(described_class::Contract.matches?(struct)).to be false }
        end

        describe 'with a matching struct' do
          let(:attributes) { { 'size' => 'Colossal' } }

          it 'should not have any errors' do
            expect(described_class::Contract.errors_for(struct)).to be == []
          end

          it { expect(described_class::Contract.matches?(struct)).to be true }
        end
      end

      wrap_context 'when the subclass defines constraints' do
        it { expect(constraints.size).to be 2 }

        describe 'with an empty struct' do
          let(:expected_errors) do
            [
              {
                data:    { required: true, type: String },
                message: nil,
                path:    [:size],
                type:    'stannum.constraints.is_not_type'
              },
              {
                data:    {},
                message: nil,
                path:    [:size],
                type:    'stannum.constraints.invalid'
              }
            ]
          end

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(struct))
              .to be == expected_errors
          end

          it { expect(described_class::Contract.matches?(struct)).to be false }
        end

        describe 'with a non-matching struct' do
          let(:attributes) { { size: 'Lilliputian' } }
          let(:expected_errors) do
            [
              {
                data:    {},
                message: nil,
                path:    [:size],
                type:    'stannum.constraints.invalid'
              }
            ]
          end

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(struct))
              .to be == expected_errors
          end

          it { expect(described_class::Contract.matches?(struct)).to be false }
        end

        describe 'with a matching struct' do
          let(:attributes) { { 'size' => 'Huge' } }

          it 'should not have any errors' do
            expect(described_class::Contract.errors_for(struct)).to be == []
          end

          it { expect(described_class::Contract.matches?(struct)).to be true }
        end
      end

      context 'when the struct and subclass define constraints' do
        include_context 'when the struct defines constraints'
        include_context 'when the subclass defines constraints'

        it { expect(constraints.size).to be 8 }

        describe 'with an empty struct' do
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
              },
              {
                data:    { required: true, type: String },
                message: nil,
                path:    [:size],
                type:    'stannum.constraints.is_not_type'
              },
              {
                data:    {},
                message: nil,
                path:    [:size],
                type:    'stannum.constraints.invalid'
              }
            ]
          end

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(struct))
              .to be == expected_errors
          end

          it { expect(described_class::Contract.matches?(struct)).to be false }
        end

        describe 'with a non-matching struct' do
          let(:attributes) do
            {
              name:        '',
              description: :invalid,
              quantity:    -10,
              size:        'Lilliputian'
            }
          end
          let(:expected_errors) do
            [
              {
                data:    {},
                message: nil,
                path:    [:name],
                type:    'stannum.constraints.absent'
              },
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
              },
              {
                data:    {},
                message: nil,
                path:    [:size],
                type:    'stannum.constraints.invalid'
              }
            ]
          end

          it 'should return the errors' do
            expect(described_class::Contract.errors_for(struct))
              .to be == expected_errors
          end

          it { expect(described_class::Contract.matches?(struct)).to be false }
        end

        describe 'with a matching struct' do
          let(:attributes) do
            {
              name:        'Self-sealing Stem Bolt',
              description: 'No one is quite sure what this thing is.',
              quantity:    1_000,
              size:        'Huge'
            }
          end

          it 'should not have any errors' do
            expect(described_class::Contract.errors_for(struct)).to be == []
          end

          it { expect(described_class::Contract.matches?(struct)).to be true }
        end
      end
    end
  end

  describe '.attribute' do
    shared_examples 'should define the attribute' do
      let(:expected) do
        an_instance_of(Stannum::Attribute)
          .and(
            have_attributes(
              name:    attr_name.to_s,
              type:    attr_type.to_s,
              options: { required: true }.merge(options)
            )
          )
      end

      it 'should add the attribute to ::Attributes' do
        expect { described_class.attribute(attr_name, attr_type, **options) }
          .to change { described_class.attributes.count }
          .by(1)
      end

      it 'should add the attribute key to ::Attributes' do
        expect { described_class.attribute(attr_name, attr_type, **options) }
          .to change(described_class.attributes, :each_key)
          .to include(attr_name.to_s)
      end

      it 'should add the attribute value to ::Attributes' do
        expect { described_class.attribute(attr_name, attr_type, **options) }
          .to change(described_class.attributes, :each_value)
          .to include(expected)
      end
    end

    let(:attr_name) { :price }
    let(:attr_type) { BigDecimal }
    let(:options)   { {} }

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:attribute)
        .with(2).arguments
        .and_any_keywords
    end

    describe 'with attr_name: a String' do
      let(:attr_name) { 'price' }

      it 'should return the attribute name as a Symbol' do
        expect(described_class.attribute(attr_name, attr_type, **options))
          .to be :price
      end

      include_examples 'should define the attribute'
    end

    describe 'with attr_name: a Symbol' do
      let(:attr_name) { :price }

      it 'should return the attribute name as a Symbol' do
        expect(described_class.attribute(attr_name, attr_type, **options))
          .to be :price
      end

      include_examples 'should define the attribute'
    end

    describe 'with options: value' do
      let(:options) { { key: 'value' } }

      include_examples 'should define the attribute'
    end

    wrap_context 'when the struct defines attributes' do
      include_examples 'should define the attribute'

      describe 'with options: value' do
        let(:options) { { key: 'value' } }

        include_examples 'should define the attribute'
      end
    end
  end

  describe '.attributes' do
    let(:attributes) { described_class.attributes }

    it { expect(described_class).to respond_to(:attributes).with(0).arguments }

    it { expect(described_class.attributes).to be described_class::Attributes }
  end

  describe '.constraint' do
    let(:constraint) { Stannum::Constraint.new {} }

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
      it 'should raise an error' do
        expect { described_class.constraint(Object.new.freeze) }
          .to raise_error ArgumentError, 'attribute must be a String or Symbol'
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
        expect { described_class.constraint {} }
          .to change { constraints.size } # rubocop:disable RSpec/ExpectChange
          .by(1)
      end

      it 'should create an anonymous constraint' do
        expect do |block|
          described_class.constraint(&block)

          constraint = constraints.last.constraint

          constraint.matches?(struct)
        end
          .to yield_with_args(struct)
      end
    end

    describe 'with attribute name: a String and a block' do
      let(:value) { 'Self-sealing Stem Bolt' }

      it 'should add the constraint to the contract' do
        expect { described_class.constraint('name') {} }
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
        expect { described_class.constraint(:name) {} }
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
              constraint: constraint,
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
              constraint: constraint,
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
              constraint: constraint,
              property:   nil
            )
          )
      end
    end

    wrap_context 'when the struct defines constraints' do
      describe 'with a block' do
        it 'should add the constraint to the contract' do
          expect { described_class.constraint {} }
            .to change { constraints.size } # rubocop:disable RSpec/ExpectChange
            .by(1)
        end

        it 'should create an anonymous constraint' do
          expect do |block|
            described_class.constraint(&block)

            constraint = constraints.last.constraint

            constraint.matches?(struct)
          end
            .to yield_with_args(struct)
        end
      end

      describe 'with attribute name: a String and a block' do
        let(:value) { 'Self-sealing Stem Bolt' }

        it 'should add the constraint to the contract' do
          expect { described_class.constraint('name') {} }
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
          expect { described_class.constraint(:name) {} }
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
                constraint: constraint,
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
                constraint: constraint,
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
                constraint: constraint,
                property:   nil
              )
            )
        end
      end
    end
  end

  describe '.contract' do
    it { expect(described_class).to respond_to(:contract).with(0).arguments }

    it { expect(described_class.contract).to be described_class::Contract }
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0..1).arguments }

    describe 'with no arguments' do
      it { expect(described_class.new.attributes).to be == {} }
    end

    describe 'with nil' do
      it 'should raise an error' do
        expect { described_class.new(nil) }
          .to raise_error ArgumentError, 'attributes must be a Hash'
      end
    end

    describe 'with an Object' do
      it 'should raise an error' do
        expect { described_class.new(Object.new.freeze) }
          .to raise_error ArgumentError, 'attributes must be a Hash'
      end
    end

    describe 'with a nil key' do
      it 'should raise an error' do
        expect { described_class.new(nil => 'value') }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an Object key' do
      it 'should raise an error' do
        expect { described_class.new(Object.new.freeze => 'value') }
          .to raise_error ArgumentError, 'attribute must be a String or Symbol'
      end
    end

    describe 'with an empty String key' do
      it 'should raise an error' do
        expect { described_class.new('' => 'value') }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an empty Symbol key' do
      it 'should raise an error' do
        expect { described_class.new('': 'value') }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an invalid String key' do
      it 'should raise an error' do
        expect { described_class.new('invalid' => 'value') }
          .to raise_error ArgumentError, 'unknown attribute "invalid"'
      end
    end

    describe 'with an invalid Symbol key' do
      it 'should raise an error' do
        expect { described_class.new(invalid: 'value') }
          .to raise_error ArgumentError, 'unknown attribute :invalid'
      end
    end

    describe 'with an empty Hash' do
      it { expect(described_class.new({}).attributes).to be == {} }
    end

    wrap_context 'when the struct defines attributes' do
      describe 'with no arguments' do
        let(:expected) do
          {
            'name'        => nil,
            'description' => nil,
            'quantity'    => 0
          }
        end

        it { expect(described_class.new.attributes).to be == expected }
      end

      describe 'with an invalid String key' do
        it 'should raise an error' do
          expect { described_class.new('invalid' => 'value') }
            .to raise_error ArgumentError, 'unknown attribute "invalid"'
        end
      end

      describe 'with an invalid Symbol key' do
        it 'should raise an error' do
          expect { described_class.new(invalid: 'value') }
            .to raise_error ArgumentError, 'unknown attribute :invalid'
        end
      end

      describe 'with an empty Hash' do
        let(:expected) do
          {
            'name'        => nil,
            'description' => nil,
            'quantity'    => 0
          }
        end

        it { expect(described_class.new({}).attributes).to be == expected }
      end

      describe 'with a Hash with String keys with some attributes' do
        let(:attributes) { { 'name' => 'Self-sealing Stem Bolt' } }
        let(:expected) do
          {
            'name'        => 'Self-sealing Stem Bolt',
            'description' => nil,
            'quantity'    => 0
          }
        end

        it 'should set the attributes' do
          expect(described_class.new(attributes).attributes).to be == expected
        end
      end

      describe 'with a Hash with Symbol keys with some attributes' do
        let(:attributes) { { name: 'Self-sealing Stem Bolt' } }
        let(:expected) do
          {
            'name'        => 'Self-sealing Stem Bolt',
            'description' => nil,
            'quantity'    => 0
          }
        end

        it 'should set the attributes' do
          expect(described_class.new(attributes).attributes).to be == expected
        end
      end

      describe 'with a Hash with String keys with all attributes' do
        let(:attributes) do
          {
            'name'        => 'Self-sealing Stem Bolt',
            'description' => 'No one is quite sure what this thing is.',
            'quantity'    => 1_000
          }
        end
        let(:expected) { attributes }

        it 'should set the attributes' do
          expect(described_class.new(attributes).attributes).to be == expected
        end
      end

      describe 'with a Hash with Symbol keys with all attributes' do
        let(:attributes) do
          {
            name:        'Self-sealing Stem Bolt',
            description: 'No one is quite sure what this thing is.',
            quantity:    1_000
          }
        end
        let(:expected) do
          tools.hash_tools.convert_keys_to_strings(attributes)
        end

        it 'should set the attributes' do
          expect(described_class.new(attributes).attributes).to be == expected
        end
      end
    end
  end

  describe '#:attribute' do
    it { expect(struct).not_to respond_to(:name) }

    wrap_context 'when the struct defines attributes' do
      it { expect(struct).to respond_to(:name).with(0).arguments }

      it { expect(struct.name).to be nil }

      context 'when the attribute has a default value' do
        it { expect(struct.quantity).to be 0 }
      end
    end

    wrap_context 'when the struct has attribute values' do
      it { expect(struct.name).to be == attributes['name'] }
    end

    wrap_context 'with a struct subclass' do
      it { expect(struct).not_to respond_to(:name) }

      wrap_context 'when the struct defines attributes' do
        it { expect(struct).to respond_to(:name).with(0).arguments }

        it { expect(struct.name).to be nil }

        context 'when the attribute has a default value' do
          it { expect(struct.quantity).to be 0 }
        end
      end

      wrap_context 'when the struct has attribute values' do
        it { expect(struct.name).to be == attributes['name'] }
      end

      wrap_context 'when the subclass defines attributes' do
        it { expect(struct).to respond_to(:size).with(0).arguments }

        it { expect(struct.size).to be nil }
      end

      wrap_context 'when the subclass has attribute values' do
        it { expect(struct.size).to be == attributes['size'] }
      end
    end
  end

  describe '#:attribute=' do
    it { expect(struct).not_to respond_to(:name=) }

    wrap_context 'when the struct defines attributes' do
      it { expect(struct).to respond_to(:name=).with(1).argument }

      it 'should update the attribute' do
        expect { struct.name = 'Can of Headlight Fluid' }
          .to change(struct, :name)
          .to be == 'Can of Headlight Fluid'
      end
    end

    wrap_context 'with a struct subclass' do
      wrap_context 'when the struct defines attributes' do
        it { expect(struct).to respond_to(:name=).with(1).argument }

        it 'should update the attribute' do
          expect { struct.name = 'Can of Headlight Fluid' }
            .to change(struct, :name)
            .to be == 'Can of Headlight Fluid'
        end
      end

      wrap_context 'when the subclass defines attributes' do
        it { expect(struct).to respond_to(:size=).with(1).argument }

        it 'should update the attribute' do
          expect { struct.size = 'Colossal' }
            .to change(struct, :size)
            .to be == 'Colossal'
        end
      end
    end
  end

  describe '#==' do
    describe 'with nil' do
      # rubocop:disable Style/NilComparison
      it { expect(struct == nil).to be false }
      # rubocop:enable Style/NilComparison
    end

    describe 'with an Object' do
      it { expect(struct == Object.new.freeze).to be false }
    end

    describe 'with an attributes hash' do
      it { expect(struct == {}).to be false }
    end

    describe 'with a struct instance' do
      it { expect(struct == described_class.new).to be true }
    end

    wrap_context 'when the struct defines attributes' do
      describe 'with a struct instance with non-matching attributes' do
        let(:other) { described_class.new('name' => 'Can of Headlight Fluid') }

        it { expect(struct == other).to be false }
      end

      describe 'with a struct instance with matching attributes' do
        it { expect(struct == described_class.new).to be true }
      end
    end

    wrap_context 'when the struct has attribute values' do
      describe 'with a struct instance with non-matching attributes' do
        let(:other) do
          described_class.new(
            attributes.merge('name' => 'Can of Headlight Fluid')
          )
        end

        it { expect(struct == other).to be false }
      end

      describe 'with a struct instance with matching attributes' do
        it { expect(struct == described_class.new(attributes)).to be true }
      end
    end

    wrap_context 'with a struct subclass' do
      describe 'with a struct instance' do
        it { expect(struct == described_class.new).to be true }
      end

      describe 'with an instance of a child class' do
        it { expect(Spec::CustomStruct.new == struct).to be false }
      end

      describe 'with an instance of a parent class' do
        it { expect(struct == Spec::CustomStruct.new).to be false }
      end

      wrap_context 'when the struct defines attributes' do
        let(:parent) { Spec::CustomStruct.new }

        describe 'with a struct instance with non-matching attributes' do
          let(:other) do
            described_class.new('name' => 'Can of Headlight Fluid')
          end

          it { expect(struct == other).to be false }
        end

        describe 'with a struct instance with matching attributes' do
          it { expect(struct == described_class.new).to be true }
        end

        describe 'with an instance of a child class' do
          it { expect(parent == struct).to be false }
        end

        describe 'with an instance of a parent class' do
          it { expect(struct == parent).to be false }
        end
      end

      wrap_context 'when the struct has attribute values' do
        let(:parent) { Spec::CustomStruct.new(attributes) }

        describe 'with a struct instance with non-matching attributes' do
          let(:other) do
            described_class.new(
              attributes.merge('name' => 'Can of Headlight Fluid')
            )
          end

          it { expect(struct == other).to be false }
        end

        describe 'with a struct instance with matching attributes' do
          it { expect(struct == described_class.new(attributes)).to be true }
        end

        describe 'with an instance of a child class' do
          it { expect(parent == struct).to be false }
        end

        describe 'with an instance of a parent class' do
          it { expect(struct == parent).to be false }
        end
      end

      wrap_context 'when the subclass defines attributes' do
        let(:parent) { Spec::CustomStruct.new }

        describe 'with a struct instance with non-matching attributes' do
          let(:other) do
            described_class.new('size' => 'Gargantuan')
          end

          it { expect(struct == other).to be false }
        end

        describe 'with a struct instance with matching attributes' do
          it { expect(struct == described_class.new).to be true }
        end

        describe 'with an instance of a child class' do
          it { expect(parent == struct).to be false }
        end

        describe 'with an instance of a parent class' do
          it { expect(struct == parent).to be false }
        end
      end

      wrap_context 'when the subclass has attribute values' do
        let(:parent) { Spec::CustomStruct.new(attributes) }

        describe 'with a struct instance with non-matching attributes' do
          let(:other) do
            described_class.new(attributes.merge('size' => 'Gargantuan'))
          end

          it { expect(struct == other).to be false }
        end

        describe 'with a struct instance with matching attributes' do
          it { expect(struct == described_class.new(attributes)).to be true }
        end
      end
    end
  end

  describe '#[]' do
    it { expect(struct).to respond_to(:[]).with(1).argument }

    describe 'with a nil key' do
      it 'should raise an error' do
        expect { struct[nil] }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an Object key' do
      it 'should raise an error' do
        expect { struct[Object.new.freeze] }
          .to raise_error ArgumentError, 'attribute must be a String or Symbol'
      end
    end

    describe 'with an empty String key' do
      it 'should raise an error' do
        expect { struct[''] }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an empty Symbol key' do
      it 'should raise an error' do
        expect { struct[:''] }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an invalid String key' do
      it 'should raise an error' do
        expect { struct['invalid'] }
          .to raise_error ArgumentError, 'unknown attribute "invalid"'
      end
    end

    describe 'with an invalid Symbol key' do
      it 'should raise an error' do
        expect { struct[:invalid] }
          .to raise_error ArgumentError, 'unknown attribute :invalid'
      end
    end

    wrap_context 'when the struct defines attributes' do
      describe 'with an invalid String key' do
        it 'should raise an error' do
          expect { struct['invalid'] }
            .to raise_error ArgumentError, 'unknown attribute "invalid"'
        end
      end

      describe 'with an invalid Symbol key' do
        it 'should raise an error' do
          expect { struct[:invalid] }
            .to raise_error ArgumentError, 'unknown attribute :invalid'
        end
      end

      describe 'with a valid String key' do
        it { expect(struct['name']).to be nil }
      end

      describe 'with a valid Symbol key' do
        it { expect(struct[:name]).to be nil }
      end

      context 'when the attribute has a default value' do
        describe 'with a valid String key' do
          it { expect(struct['quantity']).to be 0 }
        end

        describe 'with a valid Symbol key' do
          it { expect(struct[:quantity]).to be 0 }
        end
      end
    end

    wrap_context 'when the struct has attribute values' do
      describe 'with a valid String key' do
        it { expect(struct['name']).to be attributes['name'] }
      end

      describe 'with a valid Symbol key' do
        it { expect(struct[:name]).to be attributes['name'] }
      end
    end

    wrap_context 'with a struct subclass' do
      describe 'with an invalid String key' do
        it 'should raise an error' do
          expect { struct['invalid'] }
            .to raise_error ArgumentError, 'unknown attribute "invalid"'
        end
      end

      describe 'with an invalid Symbol key' do
        it 'should raise an error' do
          expect { struct[:invalid] }
            .to raise_error ArgumentError, 'unknown attribute :invalid'
        end
      end

      wrap_context 'when the struct defines attributes' do
        describe 'with an invalid String key' do
          it 'should raise an error' do
            expect { struct['invalid'] }
              .to raise_error ArgumentError, 'unknown attribute "invalid"'
          end
        end

        describe 'with an invalid Symbol key' do
          it 'should raise an error' do
            expect { struct[:invalid] }
              .to raise_error ArgumentError, 'unknown attribute :invalid'
          end
        end

        describe 'with a valid String key' do
          it { expect(struct['name']).to be nil }
        end

        describe 'with a valid Symbol key' do
          it { expect(struct[:name]).to be nil }
        end

        context 'when the attribute has a default value' do
          describe 'with a valid String key' do # rubocop:disable RSpec/NestedGroups
            it { expect(struct['quantity']).to be 0 }
          end

          describe 'with a valid Symbol key' do # rubocop:disable RSpec/NestedGroups
            it { expect(struct[:quantity]).to be 0 }
          end
        end
      end

      wrap_context 'when the struct has attribute values' do
        describe 'with a valid String key' do
          it { expect(struct['name']).to be attributes['name'] }
        end

        describe 'with a valid Symbol key' do
          it { expect(struct[:name]).to be attributes['name'] }
        end
      end

      wrap_context 'when the subclass defines attributes' do
        describe 'with a valid String key' do
          it { expect(struct['size']).to be nil }
        end

        describe 'with a valid Symbol key' do
          it { expect(struct[:size]).to be nil }
        end
      end

      wrap_context 'when the subclass has attribute values' do
        describe 'with a valid String key' do
          it { expect(struct['size']).to be attributes['size'] }
        end

        describe 'with a valid Symbol key' do
          it { expect(struct[:size]).to be attributes['size'] }
        end
      end
    end
  end

  describe '#[]=' do
    let(:value) { 'Can of Headlight Fluid' }

    it { expect(struct).to respond_to(:[]=).with(2).arguments }

    describe 'with a nil key' do
      it 'should raise an error' do
        expect { struct[nil] = value }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an Object key' do
      it 'should raise an error' do
        expect { struct[Object.new.freeze] = value }
          .to raise_error ArgumentError, 'attribute must be a String or Symbol'
      end
    end

    describe 'with an empty String key' do
      it 'should raise an error' do
        expect { struct[''] = value }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an empty Symbol key' do
      it 'should raise an error' do
        expect { struct[:''] = value }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an invalid String key' do
      it 'should raise an error' do
        expect { struct['invalid'] = value }
          .to raise_error ArgumentError, 'unknown attribute "invalid"'
      end
    end

    describe 'with an invalid Symbol key' do
      it 'should raise an error' do
        expect { struct[:invalid] = value }
          .to raise_error ArgumentError, 'unknown attribute :invalid'
      end
    end

    wrap_context 'when the struct defines attributes' do
      describe 'with an invalid String key' do
        it 'should raise an error' do
          expect { struct['invalid'] = value }
            .to raise_error ArgumentError, 'unknown attribute "invalid"'
        end
      end

      describe 'with an invalid Symbol key' do
        it 'should raise an error' do
          expect { struct[:invalid] = value }
            .to raise_error ArgumentError, 'unknown attribute :invalid'
        end
      end

      describe 'with a valid String key' do
        it 'should set the attribute' do
          expect { struct['name'] = value }
            .to change { struct['name'] }
            .to be value
        end
      end

      describe 'with a valid Symbol key' do
        it 'should set the attribute' do
          expect { struct[:name] = value }
            .to change { struct[:name] }
            .to be value
        end
      end
    end

    wrap_context 'with a struct subclass' do
      let(:value) { 'Colossal' }

      describe 'with an invalid String key' do
        it 'should raise an error' do
          expect { struct['invalid'] = value }
            .to raise_error ArgumentError, 'unknown attribute "invalid"'
        end
      end

      describe 'with an invalid Symbol key' do
        it 'should raise an error' do
          expect { struct[:invalid] = value }
            .to raise_error ArgumentError, 'unknown attribute :invalid'
        end
      end

      wrap_context 'when the struct defines attributes' do
        describe 'with an invalid String key' do
          it 'should raise an error' do
            expect { struct['invalid'] = value }
              .to raise_error ArgumentError, 'unknown attribute "invalid"'
          end
        end

        describe 'with an invalid Symbol key' do
          it 'should raise an error' do
            expect { struct[:invalid] = value }
              .to raise_error ArgumentError, 'unknown attribute :invalid'
          end
        end

        describe 'with a valid String key' do
          it 'should set the attribute' do
            expect { struct['name'] = value }
              .to change { struct['name'] }
              .to be value
          end
        end

        describe 'with a valid Symbol key' do
          it 'should set the attribute' do
            expect { struct[:name] = value }
              .to change { struct[:name] }
              .to be value
          end
        end
      end

      wrap_context 'when the subclass defines attributes' do
        describe 'with an invalid String key' do
          it 'should raise an error' do
            expect { struct['invalid'] = value }
              .to raise_error ArgumentError, 'unknown attribute "invalid"'
          end
        end

        describe 'with an invalid Symbol key' do
          it 'should raise an error' do
            expect { struct[:invalid] = value }
              .to raise_error ArgumentError, 'unknown attribute :invalid'
          end
        end

        describe 'with a valid String key' do
          it 'should set the attribute' do
            expect { struct['size'] = value }
              .to change { struct['size'] }
              .to be value
          end
        end

        describe 'with a valid Symbol key' do
          it 'should set the attribute' do
            expect { struct[:size] = value }
              .to change { struct[:size] }
              .to be value
          end
        end
      end
    end
  end

  describe '#assign_attributes' do
    it { expect(struct).to respond_to(:assign_attributes).with(1).argument }

    it { expect(struct).to alias_method(:assign_attributes).as(:assign) }

    describe 'with nil' do
      it 'should raise an error' do
        expect { struct.assign_attributes(nil) }
          .to raise_error ArgumentError, 'attributes must be a Hash'
      end
    end

    describe 'with an Object' do
      it 'should raise an error' do
        expect { struct.assign_attributes(Object.new.freeze) }
          .to raise_error ArgumentError, 'attributes must be a Hash'
      end
    end

    describe 'with a nil key' do
      it 'should raise an error' do
        expect { struct.assign_attributes(nil => 'value') }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an Object key' do
      it 'should raise an error' do
        expect { struct.assign_attributes(Object.new.freeze => 'value') }
          .to raise_error ArgumentError, 'attribute must be a String or Symbol'
      end
    end

    describe 'with an empty String key' do
      it 'should raise an error' do
        expect { struct.assign_attributes('' => 'value') }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an empty Symbol key' do
      it 'should raise an error' do
        expect { struct.assign_attributes('': 'value') }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an invalid String key' do
      it 'should raise an error' do
        expect { struct.assign_attributes('invalid' => 'value') }
          .to raise_error ArgumentError, 'unknown attribute "invalid"'
      end
    end

    describe 'with an invalid Symbol key' do
      it 'should raise an error' do
        expect { struct.assign_attributes(invalid: 'value') }
          .to raise_error ArgumentError, 'unknown attribute :invalid'
      end
    end

    describe 'with an empty Hash' do
      it 'should not change the attributes' do
        expect { struct.assign_attributes({}) }
          .not_to change(struct, :attributes)
      end
    end

    wrap_context 'when the struct defines attributes' do
      describe 'with an invalid String key' do
        it 'should raise an error' do
          expect { struct.assign_attributes('invalid' => 'value') }
            .to raise_error ArgumentError, 'unknown attribute "invalid"'
        end
      end

      describe 'with an invalid Symbol key' do
        it 'should raise an error' do
          expect { struct.assign_attributes(invalid: 'value') }
            .to raise_error ArgumentError, 'unknown attribute :invalid'
        end
      end

      describe 'with an empty Hash' do
        it 'should not change the attributes' do
          expect { struct.assign_attributes({}) }
            .not_to change(struct, :attributes)
        end
      end

      describe 'with a Hash with String keys with some attributes' do
        let(:new_attributes) { { 'name' => 'Can of Headlight Fluid' } }
        let(:expected) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => nil,
            'quantity'    => 0
          }
        end

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer method' do
          allow(struct).to receive(:name=)

          struct.assign_attributes(new_attributes)

          expect(struct).to have_received(:name=).with('Can of Headlight Fluid')
        end
      end

      describe 'with a Hash with Symbol keys with some attributes' do
        let(:new_attributes) { { name: 'Can of Headlight Fluid' } }
        let(:expected) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => nil,
            'quantity'    => 0
          }
        end

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer method' do
          allow(struct).to receive(:name=)

          struct.assign_attributes(new_attributes)

          expect(struct).to have_received(:name=).with('Can of Headlight Fluid')
        end
      end

      describe 'with a Hash with String keys with all attributes' do
        let(:new_attributes) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => 'Used to recharge the motor pool headlights',
            'quantity'    => 5
          }
        end
        let(:expected) { new_attributes }

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.assign_attributes(new_attributes)

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(new_attributes[method_name.to_s])
          end
        end
      end

      describe 'with a Hash with Symbol keys with all attributes' do
        let(:new_attributes) do
          {
            name:        'Can of Headlight Fluid',
            description: 'Used to recharge the motor pool headlights',
            quantity:    5
          }
        end
        let(:expected) do
          tools.hash_tools.convert_keys_to_strings(new_attributes)
        end

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.assign_attributes(new_attributes)

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(new_attributes[method_name.intern])
          end
        end
      end
    end

    wrap_context 'when the struct has attribute values' do
      describe 'with an empty Hash' do
        it 'should not change the attributes' do
          expect { struct.assign_attributes({}) }
            .not_to change(struct, :attributes)
        end
      end

      describe 'with a Hash with String keys with some attributes' do
        let(:new_attributes) { { 'name' => 'Can of Headlight Fluid' } }
        let(:expected) do
          attributes.merge('name' => 'Can of Headlight Fluid')
        end

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer method' do
          allow(struct).to receive(:name=)

          struct.assign_attributes(new_attributes)

          expect(struct).to have_received(:name=).with('Can of Headlight Fluid')
        end
      end

      describe 'with a Hash with Symbol keys with some attributes' do
        let(:new_attributes) { { name: 'Can of Headlight Fluid' } }
        let(:expected) do
          attributes.merge('name' => 'Can of Headlight Fluid')
        end

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer method' do
          allow(struct).to receive(:name=)

          struct.assign_attributes(new_attributes)

          expect(struct).to have_received(:name=).with('Can of Headlight Fluid')
        end
      end

      describe 'with a Hash with String keys with all attributes' do
        let(:new_attributes) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => 'Used to recharge the motor pool headlights',
            'quantity'    => 5
          }
        end
        let(:expected) { new_attributes }

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.assign_attributes(new_attributes)

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(new_attributes[method_name.to_s])
          end
        end
      end

      describe 'with a Hash with Symbol keys with all attributes' do
        let(:new_attributes) do
          {
            name:        'Can of Headlight Fluid',
            description: 'Used to recharge the motor pool headlights',
            quantity:    5
          }
        end
        let(:expected) do
          tools.hash_tools.convert_keys_to_strings(new_attributes)
        end

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.assign_attributes(new_attributes)

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(new_attributes[method_name.intern])
          end
        end
      end
    end

    wrap_context 'with a struct subclass' do
      describe 'with an empty Hash' do
        it 'should not change the attributes' do
          expect { struct.assign_attributes({}) }
            .not_to change(struct, :attributes)
        end
      end

      wrap_context 'when the subclass defines attributes' do
        describe 'with an invalid String key' do
          it 'should raise an error' do
            expect { struct.assign_attributes('invalid' => 'value') }
              .to raise_error ArgumentError, 'unknown attribute "invalid"'
          end
        end

        describe 'with an invalid Symbol key' do
          it 'should raise an error' do
            expect { struct.assign_attributes(invalid: 'value') }
              .to raise_error ArgumentError, 'unknown attribute :invalid'
          end
        end

        describe 'with an empty Hash' do
          it 'should not change the attributes' do
            expect { struct.assign_attributes({}) }
              .not_to change(struct, :attributes)
          end
        end

        describe 'with a Hash with String keys' do
          let(:new_attributes) { { 'size' => 'Colossal' } }
          let(:expected)       { { 'size' => 'Colossal' } }

          it 'should update the attributes' do
            expect { struct.assign_attributes(new_attributes) }
              .to change(struct, :attributes)
              .to be == expected
          end

          it 'should call the writer method' do
            allow(struct).to receive(:size=)

            struct.assign_attributes(new_attributes)

            expect(struct).to have_received(:size=).with('Colossal')
          end
        end

        describe 'with a Hash with Symbol keys' do
          let(:new_attributes) { { size: 'Colossal' } }
          let(:expected)       { { 'size' => 'Colossal' } }

          it 'should update the attributes' do
            expect { struct.assign_attributes(new_attributes) }
              .to change(struct, :attributes)
              .to be == expected
          end

          it 'should call the writer method' do
            allow(struct).to receive(:size=)

            struct.assign_attributes(new_attributes)

            expect(struct).to have_received(:size=).with('Colossal')
          end
        end
      end

      wrap_context 'when the subclass has attribute values' do
        describe 'with an empty Hash' do
          it 'should not change the attributes' do
            expect { struct.assign_attributes({}) }
              .not_to change(struct, :attributes)
          end
        end

        describe 'with a Hash with String keys' do
          let(:new_attributes) { { 'size' => 'Colossal' } }
          let(:expected) do
            attributes.merge('size' => 'Colossal')
          end

          it 'should update the attributes' do
            expect { struct.assign_attributes(new_attributes) }
              .to change(struct, :attributes)
              .to be == expected
          end

          it 'should call the writer method' do
            allow(struct).to receive(:size=)

            struct.assign_attributes(new_attributes)

            expect(struct).to have_received(:size=).with('Colossal')
          end
        end

        describe 'with a Hash with Symbol keys' do
          let(:new_attributes) { { size: 'Colossal' } }
          let(:expected) do
            attributes.merge('size' => 'Colossal')
          end

          it 'should update the attributes' do
            expect { struct.assign_attributes(new_attributes) }
              .to change(struct, :attributes)
              .to be == expected
          end

          it 'should call the writer method' do
            allow(struct).to receive(:size=)

            struct.assign_attributes(new_attributes)

            expect(struct).to have_received(:size=).with('Colossal')
          end
        end
      end
    end
  end

  describe '#attributes' do
    it { expect(struct).to respond_to(:attributes).with(0).arguments }

    it { expect(struct).to alias_method(:attributes).as(:to_h) }

    it { expect(struct.attributes).to be == {} }

    it 'should return a copy' do
      expect { struct.attributes['name'] = 'Can of Headlight Fluid' }
        .not_to change(struct, :attributes)
    end

    wrap_context 'when the struct defines attributes' do
      let(:expected) do
        {
          'name'        => nil,
          'description' => nil,
          'quantity'    => 0
        }
      end

      it { expect(struct.attributes).to be == expected }

      it 'should return a copy' do
        expect { struct.attributes['name'] = 'Can of Headlight Fluid' }
          .not_to change(struct, :attributes)
      end
    end

    wrap_context 'when the struct has attribute values' do
      it { expect(struct.attributes).to be == attributes }

      it 'should return a copy' do
        expect { struct.attributes['name'] = 'Can of Headlight Fluid' }
          .not_to change(struct, :attributes)
      end
    end

    wrap_context 'with a struct subclass' do
      it { expect(struct.attributes).to be == {} }

      it 'should return a copy' do
        expect { struct.attributes['size'] = 'Colossal' }
          .not_to change(struct, :attributes)
      end

      wrap_context 'when the subclass defines attributes' do
        let(:expected) { { 'size' => nil } }

        it { expect(struct.attributes).to be == expected }

        it 'should return a copy' do
          expect { struct.attributes['size'] = 'Colossal' }
            .not_to change(struct, :attributes)
        end
      end

      wrap_context 'when the subclass has attribute values' do
        it { expect(struct.attributes).to be == attributes }

        it 'should return a copy' do
          expect { struct.attributes['size'] = 'Colossal' }
            .not_to change(struct, :attributes)
        end
      end
    end
  end

  describe '#attributes=' do
    it { expect(struct).to respond_to(:attributes=).with(1).argument }

    describe 'with nil' do
      it 'should raise an error' do
        expect { struct.attributes = nil }
          .to raise_error ArgumentError, 'attributes must be a Hash'
      end
    end

    describe 'with an Object' do
      it 'should raise an error' do
        expect { struct.attributes = Object.new.freeze }
          .to raise_error ArgumentError, 'attributes must be a Hash'
      end
    end

    describe 'with a nil key' do
      it 'should raise an error' do
        expect { struct.attributes = { nil => 'value' } }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an Object key' do
      it 'should raise an error' do
        expect { struct.attributes = { Object.new.freeze => 'value' } }
          .to raise_error ArgumentError, 'attribute must be a String or Symbol'
      end
    end

    describe 'with an empty String key' do
      it 'should raise an error' do
        expect { struct.attributes = { '' => 'value' } }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an empty Symbol key' do
      it 'should raise an error' do
        expect { struct.attributes = { '': 'value' } }
          .to raise_error ArgumentError, "attribute can't be blank"
      end
    end

    describe 'with an invalid String key' do
      it 'should raise an error' do
        expect { struct.attributes = { 'invalid' => 'value' } }
          .to raise_error ArgumentError, 'unknown attribute "invalid"'
      end
    end

    describe 'with an invalid Symbol key' do
      it 'should raise an error' do
        expect { struct.attributes = { invalid: 'value' } }
          .to raise_error ArgumentError, 'unknown attribute :invalid'
      end
    end

    describe 'with an empty Hash' do
      it 'should not change the attributes' do
        expect { struct.attributes = {} }
          .not_to change(struct, :attributes)
      end
    end

    wrap_context 'when the struct defines attributes' do
      describe 'with an invalid String key' do
        it 'should raise an error' do
          expect { struct.attributes = { 'invalid' => 'value' } }
            .to raise_error ArgumentError, 'unknown attribute "invalid"'
        end
      end

      describe 'with an invalid Symbol key' do
        it 'should raise an error' do
          expect { struct.attributes = { invalid: 'value' } }
            .to raise_error ArgumentError, 'unknown attribute :invalid'
        end
      end

      describe 'with an empty Hash' do
        it 'should not change the attributes' do
          expect { struct.attributes = {} }
            .not_to change(struct, :attributes)
        end
      end

      describe 'with a Hash with String keys with some attributes' do
        let(:new_attributes) { { 'name' => 'Can of Headlight Fluid' } }
        let(:expected) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => nil,
            'quantity'    => 0
          }
        end

        it 'should update the attributes' do
          expect { struct.attributes = new_attributes }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.attributes = new_attributes

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(expected[method_name.to_s])
          end
        end
      end

      describe 'with a Hash with Symbol keys with some attributes' do
        let(:new_attributes) { { name: 'Can of Headlight Fluid' } }
        let(:expected) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => nil,
            'quantity'    => 0
          }
        end

        it 'should update the attributes' do
          expect { struct.attributes = new_attributes }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.attributes = new_attributes

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(expected[method_name.to_s])
          end
        end
      end

      describe 'with a Hash with String keys with all attributes' do
        let(:new_attributes) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => 'Used to recharge the motor pool headlights',
            'quantity'    => 5
          }
        end
        let(:expected) { new_attributes }

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.assign_attributes(new_attributes)

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(new_attributes[method_name.to_s])
          end
        end
      end

      describe 'with a Hash with Symbol keys with all attributes' do
        let(:new_attributes) do
          {
            name:        'Can of Headlight Fluid',
            description: 'Used to recharge the motor pool headlights',
            quantity:    5
          }
        end
        let(:expected) do
          tools.hash_tools.convert_keys_to_strings(new_attributes)
        end

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.assign_attributes(new_attributes)

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(new_attributes[method_name.intern])
          end
        end
      end
    end

    wrap_context 'when the struct has attribute values' do
      describe 'with an empty Hash' do
        let(:expected) do
          {
            'name'        => nil,
            'description' => nil,
            'quantity'    => 0
          }
        end

        it 'should reset the attributes to their default values' do
          expect { struct.attributes = {} }
            .to change(struct, :attributes)
            .to be == expected
        end
      end

      describe 'with a Hash with String keys with some attributes' do
        let(:new_attributes) { { 'name' => 'Can of Headlight Fluid' } }
        let(:expected) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => nil,
            'quantity'    => 0
          }
        end

        it 'should update the attributes' do
          expect { struct.attributes = new_attributes }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.attributes = new_attributes

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(expected[method_name.to_s])
          end
        end
      end

      describe 'with a Hash with Symbol keys with some attributes' do
        let(:new_attributes) { { name: 'Can of Headlight Fluid' } }
        let(:expected) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => nil,
            'quantity'    => 0
          }
        end

        it 'should update the attributes' do
          expect { struct.attributes = new_attributes }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.attributes = new_attributes

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(expected[method_name.to_s])
          end
        end
      end

      describe 'with a Hash with String keys with all attributes' do
        let(:new_attributes) do
          {
            'name'        => 'Can of Headlight Fluid',
            'description' => 'Used to recharge the motor pool headlights',
            'quantity'    => 5
          }
        end
        let(:expected) { new_attributes }

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.assign_attributes(new_attributes)

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(new_attributes[method_name.to_s])
          end
        end
      end

      describe 'with a Hash with Symbol keys with all attributes' do
        let(:new_attributes) do
          {
            name:        'Can of Headlight Fluid',
            description: 'Used to recharge the motor pool headlights',
            quantity:    5
          }
        end
        let(:expected) do
          tools.hash_tools.convert_keys_to_strings(new_attributes)
        end

        it 'should update the attributes' do
          expect { struct.assign_attributes(new_attributes) }
            .to change(struct, :attributes)
            .to be == expected
        end

        it 'should call the writer methods' do
          method_names = %i[name description quantity]
          method_names.each do |method_name|
            allow(struct).to receive(:"#{method_name}=")
          end

          struct.assign_attributes(new_attributes)

          method_names.each do |method_name|
            expect(struct)
              .to have_received(:"#{method_name}=")
              .with(new_attributes[method_name.intern])
          end
        end
      end
    end

    wrap_context 'with a struct subclass' do
      describe 'with an invalid String key' do
        it 'should raise an error' do
          expect { struct.attributes = { 'invalid' => 'value' } }
            .to raise_error ArgumentError, 'unknown attribute "invalid"'
        end
      end

      describe 'with an invalid Symbol key' do
        it 'should raise an error' do
          expect { struct.attributes = { invalid: 'value' } }
            .to raise_error ArgumentError, 'unknown attribute :invalid'
        end
      end

      describe 'with an empty Hash' do
        it 'should not change the attributes' do
          expect { struct.attributes = {} }
            .not_to change(struct, :attributes)
        end
      end

      wrap_context 'when the subclass defines attributes' do
        describe 'with an invalid String key' do
          it 'should raise an error' do
            expect { struct.attributes = { 'invalid' => 'value' } }
              .to raise_error ArgumentError, 'unknown attribute "invalid"'
          end
        end

        describe 'with an invalid Symbol key' do
          it 'should raise an error' do
            expect { struct.attributes = { invalid: 'value' } }
              .to raise_error ArgumentError, 'unknown attribute :invalid'
          end
        end

        describe 'with an empty Hash' do
          it 'should not change the attributes' do
            expect { struct.attributes = {} }
              .not_to change(struct, :attributes)
          end
        end

        describe 'with a Hash with String keys' do
          let(:new_attributes) { { 'size' => 'Colossal' } }
          let(:expected)       { { 'size' => 'Colossal' } }

          it 'should update the attributes' do
            expect { struct.attributes = new_attributes }
              .to change(struct, :attributes)
              .to be == expected
          end

          it 'should call the writer method' do
            method_names = %i[size]
            method_names.each do |method_name|
              allow(struct).to receive(:"#{method_name}=")
            end

            struct.attributes = new_attributes

            method_names.each do |method_name|
              expect(struct)
                .to have_received(:"#{method_name}=")
                .with(expected[method_name.to_s])
            end
          end
        end

        describe 'with a Hash with Symbol keys' do
          let(:new_attributes) { { size: 'Colossal' } }
          let(:expected)       { { 'size' => 'Colossal' } }

          it 'should update the attributes' do
            expect { struct.attributes = new_attributes }
              .to change(struct, :attributes)
              .to be == expected
          end

          it 'should call the writer method' do
            method_names = %i[size]
            method_names.each do |method_name|
              allow(struct).to receive(:"#{method_name}=")
            end

            struct.attributes = new_attributes

            method_names.each do |method_name|
              expect(struct)
                .to have_received(:"#{method_name}=")
                .with(expected[method_name.to_s])
            end
          end
        end
      end

      wrap_context 'when the subclass has attribute values' do
        describe 'with an empty Hash' do
          let(:expected) { { 'size' => nil } }

          it 'should reset the attributes to their default values' do
            expect { struct.attributes = {} }
              .to change(struct, :attributes)
              .to be == expected
          end
        end

        describe 'with a Hash with String keys with some attributes' do
          let(:new_attributes) { { 'size' => 'Colossal' } }
          let(:expected)       { { 'size' => 'Colossal' } }

          it 'should update the attributes' do
            expect { struct.attributes = new_attributes }
              .to change(struct, :attributes)
              .to be == expected
          end

          it 'should call the writer methods' do
            method_names = %i[size]
            method_names.each do |method_name|
              allow(struct).to receive(:"#{method_name}=")
            end

            struct.attributes = new_attributes

            method_names.each do |method_name|
              expect(struct)
                .to have_received(:"#{method_name}=")
                .with(expected[method_name.to_s])
            end
          end
        end

        describe 'with a Hash with Symbol keys with some attributes' do
          let(:new_attributes) { { size: 'Colossal' } }
          let(:expected)       { { 'size' => 'Colossal' } }

          it 'should update the attributes' do
            expect { struct.attributes = new_attributes }
              .to change(struct, :attributes)
              .to be == expected
          end

          it 'should call the writer methods' do
            method_names = %i[size]
            method_names.each do |method_name|
              allow(struct).to receive(:"#{method_name}=")
            end

            struct.attributes = new_attributes

            method_names.each do |method_name|
              expect(struct)
                .to have_received(:"#{method_name}=")
                .with(expected[method_name.to_s])
            end
          end
        end
      end
    end
  end

  describe '#inspect' do
    let(:expected) { "#<#{described_class.name}>" }

    it { expect(struct.inspect).to be == expected }

    wrap_context 'when the struct defines attributes' do
      let(:expected) do
        "#<#{described_class.name} name: nil, description: nil, quantity: 0>"
      end

      it { expect(struct.inspect).to be == expected }
    end

    wrap_context 'when the struct has attribute values' do
      let(:expected) do
        "#<#{described_class.name} name: #{attributes['name'].inspect}," \
        " description: #{attributes['description'].inspect}," \
        " quantity: #{attributes['quantity'].inspect}>"
      end

      it { expect(struct.inspect).to be == expected }
    end

    wrap_context 'with a struct subclass' do
      it { expect(struct.inspect).to be == expected }

      wrap_context 'when the subclass defines attributes' do
        let(:expected) do
          "#<#{described_class.name} size: nil>"
        end

        it { expect(struct.inspect).to be == expected }
      end

      wrap_context 'when the subclass has attribute values' do
        let(:expected) do
          "#<#{described_class.name} size: #{attributes['size'].inspect}>"
        end

        it { expect(struct.inspect).to be == expected }
      end
    end
  end
end
