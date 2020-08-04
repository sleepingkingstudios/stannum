# frozen_string_literal: true

require 'stannum/errors'

RSpec.describe Stannum::Errors do
  shared_context 'when the errors has many root errors' do
    let(:raw_root_errors) do
      [
        { type: 'blank' },
        { type: 'invalid',  data: { key: 'value' } },
        { type: 'inverted', message: 'is upside down' }
      ]
    end
    let(:expected_root_errors) do
      raw_root_errors.map do |err|
        err
          .merge(data:    err[:data]    || {})
          .merge(message: err[:message] || nil)
          .merge(path:    [])
      end
    end
    let(:expected_errors) { expected_root_errors }

    before(:example) do
      raw_root_errors.each do |error|
        errors
          .add(
            error.fetch(:type),
            message: error[:message],
            **error.fetch(:data, {})
          )
      end
    end
  end

  shared_context 'when the errors has many child errors' do
    let(:child_path) { :spells }
    let(:raw_child_errors) do
      [
        { type: 'mana_exhausted' },
        { type: 'missing_component', data: { item: 'pixie dust' } },
        {
          type:    'wrong_element',
          message: "can't cast spells of that element"
        }
      ]
    end
    let(:expected_child_errors) do
      raw_child_errors.map do |err|
        err
          .merge(data:    err[:data]    || {})
          .merge(message: err[:message] || nil)
          .merge(path:    [child_path])
      end
    end
    let(:expected_errors) { expected_child_errors }

    before(:example) do
      raw_child_errors.each do |error|
        errors[child_path]
          .add(
            error.fetch(:type),
            message: error[:message],
            **error.fetch(:data, {})
          )
      end
    end
  end

  shared_context 'when the errors has many deeply nested errors' do
    let(:raw_nested_errors) do
      [
        {
          data:    {},
          message: 'is not recruiting',
          path:    [:guilds, 0],
          type:    'not_accepting_members'
        },
        {
          data:    {},
          message: nil,
          path:    [:guilds, 1, :members],
          type:    'empty'
        },
        {
          data:    { overdue_by: '3 months' },
          message: nil,
          path:    [:guilds, 2, :members, 0],
          type:    'late_paying_dues'
        }
      ]
    end
    let(:expected_nested_errors) { raw_nested_errors }
    let(:expected_errors)        { expected_nested_errors }

    before(:example) do
      raw_nested_errors.each do |error|
        errors
          .dig(error.fetch(:path, []))
          .add(
            error.fetch(:type),
            message: error[:message],
            **error.fetch(:data, {})
          )
      end
    end
  end

  shared_context 'when the errors has many errors at different paths' do
    include_context 'when the errors has many root errors'
    include_context 'when the errors has many child errors'
    include_context 'when the errors has many deeply nested errors'

    let(:expected_errors) do
      expected_root_errors + expected_child_errors + expected_nested_errors
    end
  end

  shared_context 'when the errors has many indexed errors' do
    let(:raw_indexed_errors) do
      [
        { type: 'target_invincible' },
        { type: 'target_immune', data: { damage_type: 'fire' } },
        {
          type:    'target_evaded',
          message: 'target was able to evade your fireball'
        }
      ]
    end
    let(:expected_indexed_errors) do
      raw_indexed_errors.map.with_index do |err, index|
        err
          .merge(data:    err[:data]    || {})
          .merge(message: err[:message] || nil)
          .merge(path:    [index])
      end
    end
    let(:expected_errors) { expected_indexed_errors }

    before(:example) do
      raw_indexed_errors
        .each
        .with_index do |err, index|
          data = err.fetch(:data, {})
          errors[index].add(err[:type], message: err[:message], **data)
        end
    end
  end

  shared_context 'with another errors object' do
    let(:raw_other_errors) do
      [
        {
          data:    {},
          message: 'is not scheduled',
          path:    [:encounters, 0],
          type:    'unscheduled'
        },
        {
          data:    {},
          message: nil,
          path:    [:encounters, 1, :monsters],
          type:    'empty'
        },
        {
          data:    { hit_points: '5' },
          message: nil,
          path:    [:encounters, 2, :monsters, 0],
          type:    'wounded'
        }
      ]
    end
    let(:other_errors) do
      described_class.new.tap do |other|
        raw_other_errors.each do |error|
          other
            .dig(error.fetch(:path, []))
            .add(
              error.fetch(:type),
              message: error[:message],
              **error.fetch(:data, {})
            )
        end
      end
    end
    let(:expected_other_errors) do
      normalized_key =
        if defined?(key)
          key.is_a?(String) ? [key.intern] : [key]
        else
          []
        end

      raw_other_errors.map do |err|
        err.merge(path: [*normalized_key, *err[:path]])
      end
    end
  end

  shared_examples 'should determine the equality' do
    let(:other) { described_class.new }

    describe 'with nil' do
      it { expect(errors.send(method_name, nil)).to be false }
    end

    describe 'with an object' do
      it { expect(errors.send(method_name, Object.new.freeze)).to be false }
    end

    describe 'with an empty array' do
      it { expect(errors.send(method_name, other.to_a)).to be true }
    end

    describe 'with an empty errors object' do
      it { expect(errors.send(method_name, other)).to be true }
    end

    describe 'with an array with non-matching errors' do
      let(:other_errors) { %w[empty valid right_side_up] }

      before(:example) do
        other_errors.each { |type| other.add(type) }
      end

      it { expect(errors.send(method_name, other.to_a)).to be false }
    end

    describe 'with an errors object with non-matching errors' do
      let(:other_errors) { %w[empty valid right_side_up] }

      before(:example) do
        other_errors.each { |type| other.add(type) }
      end

      it { expect(errors.send(method_name, other)).to be false }
    end

    wrap_context 'when the errors has many root errors' do
      describe 'with nil' do
        it { expect(errors.send(method_name, nil)).to be false }
      end

      describe 'with an object' do
        it { expect(errors.send(method_name, Object.new.freeze)).to be false }
      end

      describe 'with an empty array' do
        it { expect(errors.send(method_name, [])).to be false }
      end

      describe 'with an empty errors object' do
        it { expect(errors.send(method_name, other)).to be false }
      end

      describe 'with an array with non-matching errors' do
        let(:other_errors) { %w[empty valid right_side_up] }

        before(:example) do
          other_errors.each { |type| other.add(type) }
        end

        it { expect(errors.send(method_name, other.to_a)).to be false }
      end

      describe 'with an errors object with non-matching errors' do
        let(:other_errors) { %w[empty valid right_side_up] }

        before(:example) do
          other_errors.each { |type| other.add(type) }
        end

        it { expect(errors.send(method_name, other)).to be false }
      end

      describe 'with an array with matching errors' do
        before(:example) do
          errors.each do |error|
            other
              .add(
                error.fetch(:type),
                message: error[:message],
                **error.fetch(:data, {})
              )
          end
        end

        it { expect(errors.send(method_name, other.to_a)).to be true }
      end

      describe 'with an errors object with matching errors' do
        before(:example) do
          errors.each do |error|
            other
              .add(
                error.fetch(:type),
                message: error[:message],
                **error.fetch(:data, {})
              )
          end
        end

        it { expect(errors.send(method_name, other)).to be true }
      end
    end
  end

  subject(:errors) { described_class.new }

  let(:expected_errors) { [] }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#==' do
    let(:method_name) { :== }

    include_examples 'should determine the equality'
  end

  describe '#[]' do
    let(:error_message) { 'key must be an Integer, a String or a Symbol' }

    it { expect(errors).to respond_to(:[]).with(1).argument }

    describe 'with nil' do
      it 'should raise an error' do
        expect { errors[nil] }.to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { errors[Object.new.freeze] }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an integer' do
      let(:cached) { errors[1] }

      it { expect(errors[1]).to be == described_class.new }

      it { expect(errors[1]).to be cached }
    end

    describe 'with a string' do
      let(:cached) { errors['potions'] }

      it { expect(errors['potions']).to be == described_class.new }

      it { expect(errors['potions']).to be cached }

      it { expect(errors['potions']).to be errors[:potions] }
    end

    describe 'with a symbol' do
      let(:cached) { errors[:potions] }

      it { expect(errors[:potions]).to be == described_class.new }

      it { expect(errors[:potions]).to be cached }
    end

    wrap_context 'when the errors has many child errors' do
      describe 'with a string that does not match an existing key' do
        let(:cached) { errors['potions'] }

        it { expect(errors['potions']).to be == described_class.new }

        it { expect(errors['potions']).to be cached }

        it { expect(errors['potions']).to be errors[:potions] }
      end

      describe 'with a string that matches an existing key' do
        let(:cached) { errors['spells'] }
        let(:expected_errors) do
          expected_child_errors.map { |hsh| hsh.merge(path: []) }
        end

        it { expect(errors['spells']).to be == expected_errors }

        it { expect(errors['spells']).to be cached }

        it { expect(errors['spells']).to be errors[:spells] }
      end

      describe 'with a symbol that does not match an existing key' do
        let(:cached) { errors[:potions] }

        it { expect(errors[:potions]).to be == described_class.new }

        it { expect(errors[:potions]).to be cached }
      end

      describe 'with a symbol that matches an existing key' do
        let(:cached) { errors[:spells] }
        let(:expected_errors) do
          expected_child_errors.map { |hsh| hsh.merge(path: []) }
        end

        it { expect(errors[:spells]).to be == expected_errors }

        it { expect(errors[:spells]).to be cached }
      end
    end

    wrap_context 'when the errors has many indexed errors' do
      describe 'with an integer that does not match an existing key' do
        let(:cached) { errors[3] }

        it { expect(errors[3]).to be == described_class.new }

        it { expect(errors[3]).to be cached }
      end

      describe 'with an integer that matches an existing key' do
        let(:cached) { errors[1] }
        let(:expected_errors) do
          [expected_indexed_errors[1].merge(path: [])]
        end

        it { expect(errors[1]).to be == expected_errors }

        it { expect(errors[1]).to be cached }
      end
    end
  end

  describe '#[]=' do
    shared_examples 'should update the child errors' do
      include_context 'with another errors object'

      let(:expected_errors) do
        normalized_key = key.is_a?(String) ? key.intern : key

        super().reject { |err| err[:path][0] == normalized_key }
      end
      let(:error_message) do
        'value must be an instance of Stannum::Errors, an array of error' \
        ' hashes, or nil'
      end

      before(:example) { cached } # Warm object cache.

      describe 'with nil' do
        it 'should remove the errors' do
          errors[key] = nil

          expect(errors.to_a).to contain_exactly(*expected_errors)
        end

        it 'should clear the child errors' do
          errors[key] = nil

          expect(errors[key]).to be == described_class.new
        end

        it 'should clear the cache' do
          errors[key] = nil

          expect(errors[key]).not_to be cached
        end
      end

      describe 'with an object' do
        it 'should raise an error' do
          expect { errors[key] = Object.new.freeze }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an empty Array' do
        it 'should remove the errors' do
          errors[key] = []

          expect(errors.to_a).to contain_exactly(*expected_errors)
        end

        it 'should clear the errors' do
          errors[key] = []

          expect(errors[key]).to be == described_class.new
        end

        it 'should clear the cache' do
          errors[key] = []

          expect(errors[key]).not_to be cached
        end
      end

      describe 'with an Array with nil' do
        it 'should raise an error' do
          expect { errors[key] = [nil] }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Array with an object' do
        it 'should raise an error' do
          expect { errors[key] = [Object.new.freeze] }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Array with an invalid Hash' do
        it 'should raise an error' do
          expect { errors[key] = [{}] }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Array of errors hashes' do
        let(:expected_errors) do
          super() + expected_other_errors
        end

        it 'should update the errors' do
          errors[key] = other_errors.to_a

          expect(errors.to_a).to contain_exactly(*expected_errors)
        end

        it 'should set the child errors', :aggregate_failures do
          errors[key] = other_errors.to_a

          expect(errors[key]).to be == other_errors
          expect(errors[key]).not_to be other_errors
        end

        it 'should clear the cache' do
          errors[key] = other_errors.to_a

          expect(errors[key]).not_to be cached
        end
      end

      describe 'with an empty errors object' do
        it 'should remove the errors' do
          errors[key] = described_class.new

          expect(errors.to_a).to contain_exactly(*expected_errors)
        end

        it 'should clear the errors' do
          errors[key] = described_class.new

          expect(errors[key]).to be == described_class.new
        end

        it 'should clear the cache' do
          errors[key] = described_class.new

          expect(errors[key]).not_to be cached
        end
      end

      describe 'with an errors object' do
        let(:expected_errors) do
          super() + expected_other_errors
        end

        it 'should update the errors' do
          errors[key] = other_errors

          expect(errors.to_a).to contain_exactly(*expected_errors)
        end

        it 'should copy the child errors', :aggregate_failures do
          errors[key] = other_errors

          expect(errors[key]).to be == other_errors
          expect(errors[key]).not_to be other_errors
        end

        it 'should clear the cache' do
          errors[key] = other_errors

          expect(errors[key]).not_to be cached
        end
      end
    end

    let(:error_message) { 'key must be an Integer, a String or a Symbol' }

    it { expect(errors).to respond_to(:[]=).with(2).arguments }

    describe 'with nil' do
      it 'should raise an error' do
        expect { errors[nil] = nil }.to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { errors[Object.new.freeze] = nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an integer' do
      let(:key)    { 1 }
      let(:cached) { errors[1] }

      include_examples 'should update the child errors'
    end

    describe 'with a string' do
      let(:key)    { 'potions' }
      let(:cached) { errors['potions'] }

      include_examples 'should update the child errors'
    end

    describe 'with a symbol' do
      let(:key)    { :potions }
      let(:cached) { errors[:potions] }

      include_examples 'should update the child errors'
    end

    wrap_context 'when the errors has many child errors' do
      describe 'with a string that does not match an existing key' do
        let(:key)    { 'potions' }
        let(:cached) { errors['potions'] }

        include_examples 'should update the child errors'
      end

      describe 'with a string that matches an existing key' do
        let(:key)    { 'spells' }
        let(:cached) { errors['spells'] }

        include_examples 'should update the child errors'
      end

      describe 'with a symbol that does not match an existing key' do
        let(:key)    { :potions }
        let(:cached) { errors[:potions] }

        include_examples 'should update the child errors'
      end

      describe 'with a symbol that matches an existing key' do
        let(:key)    { :spells }
        let(:cached) { errors[:spells] }

        include_examples 'should update the child errors'
      end
    end

    wrap_context 'when the errors has many deeply nested errors' do
      describe 'with a string that does not match an existing key' do
        let(:key)    { 'potions' }
        let(:cached) { errors['potions'] }

        include_examples 'should update the child errors'
      end

      describe 'with a string that matches an existing key' do
        let(:key)    { 'guilds' }
        let(:cached) { errors['guilds'] }

        include_examples 'should update the child errors'
      end

      describe 'with a symbol that does not match an existing key' do
        let(:key)    { :potions }
        let(:cached) { errors[:potions] }

        include_examples 'should update the child errors'
      end

      describe 'with a symbol that matches an existing key' do
        let(:key)    { :guilds }
        let(:cached) { errors[:guilds] }

        include_examples 'should update the child errors'
      end
    end

    wrap_context 'when the errors has many indexed errors' do
      describe 'with an integer that does not match an existing key' do
        let(:key)    { 3 }
        let(:cached) { errors[3] }

        include_examples 'should update the child errors'
      end

      describe 'with an integer that matches an existing key' do
        let(:key)    { 1 }
        let(:cached) { errors[1] }

        include_examples 'should update the child errors'
      end
    end
  end

  describe '#add' do
    it 'should define the method' do
      expect(errors)
        .to respond_to(:add)
        .with(1).argument
        .and_keywords(:message)
        .and_any_keywords
    end

    def rescue_exception
      yield
    rescue StandardError # rubocop:disable Lint/HandleExceptions
    end

    describe 'with nil' do
      it 'should raise an exception' do
        expect { errors.add nil }
          .to raise_error ArgumentError, "error type can't be nil"
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add nil } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { errors.add Object.new.freeze }
          .to raise_error ArgumentError, 'error type must be a String or Symbol'
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add Object.new.freeze } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with an empty string' do
      it 'should raise an error' do
        expect { errors.add '' }
          .to raise_error ArgumentError, "error type can't be blank"
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add '' } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with an empty symbol' do
      it 'should raise an error' do
        expect { errors.add :'' }
          .to raise_error ArgumentError, "error type can't be blank"
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add :'' } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with a string' do
      let(:expected) do
        { data: {}, message: nil, path: [], type: 'some_error' }
      end

      it { expect(errors.add 'some_error').to be errors }

      it 'should add the error' do
        expect { errors.add 'some_error' }
          .to change(errors, :to_a).to include expected
      end
    end

    describe 'with a symbol' do
      let(:expected) do
        { data: {}, message: nil, path: [], type: 'some_error' }
      end

      it { expect(errors.add :some_error).to be errors }

      it 'should add the error' do
        expect { errors.add :some_error }
          .to change(errors, :to_a).to include expected
      end
    end

    describe 'with message: nil' do
      let(:expected) do
        { data: {}, message: nil, path: [], type: 'some_error' }
      end

      it { expect(errors.add 'some_error', message: nil).to be errors }

      it 'should add the error' do
        expect { errors.add 'some_error', message: nil }
          .to change(errors, :to_a).to include expected
      end
    end

    describe 'with message: an object' do
      def add_error
        errors.add 'some_error', message: Object.new.freeze
      end

      it 'should raise an error' do
        expect { add_error }
          .to raise_error ArgumentError, 'message must be a String'
      end

      it 'should not add an error' do
        expect { rescue_exception { add_error } }.not_to change(errors, :to_a)
      end
    end

    describe 'with message: a symbol' do
      def add_error
        errors.add 'some_error', message: :some_message
      end

      it 'should raise an error' do
        expect { add_error }
          .to raise_error ArgumentError, 'message must be a String'
      end

      it 'should not add an error' do
        expect { rescue_exception { add_error } }.not_to change(errors, :to_a)
      end
    end

    describe 'with message: an empty string' do
      it 'should raise an error' do
        expect { errors.add 'some_error', message: '' }
          .to raise_error ArgumentError, "message can't be blank"
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add 'some_error', message: '' } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with message: a string' do
      let(:message) { 'something went wrong' }
      let(:expected) do
        { data: {}, message: message, path: [], type: 'some_error' }
      end

      it { expect(errors.add 'some_error', message: message).to be errors }

      it 'should add the error' do
        expect { errors.add 'some_error', message: message }
          .to change(errors, :to_a).to include expected
      end
    end

    describe 'with data' do
      let(:expected) do
        {
          data:    { min: 0, max: 10 },
          message: nil,
          path:    [],
          type:    'some_error'
        }
      end

      it { expect(errors.add 'some_error', min: 0, max: 10).to be errors }

      it 'should add the error' do
        expect { errors.add 'some_error', min: 0, max: 10 }
          .to change(errors, :to_a).to include expected
      end
    end

    wrap_context 'when the errors has many root errors' do
      describe 'with a string' do
        let(:expected) do
          { data: {}, message: nil, path: [], type: 'some_error' }
        end

        it { expect(errors.add 'some_error').to be errors }

        it 'should add the error' do
          expect { errors.add 'some_error' }
            .to change(errors, :to_a).to include expected
        end
      end

      describe 'with message: a string' do
        let(:message) { 'something went wrong' }
        let(:expected) do
          { data: {}, message: message, path: [], type: 'some_error' }
        end

        it { expect(errors.add 'some_error', message: message).to be errors }

        it 'should add the error' do
          expect { errors.add 'some_error', message: message }
            .to change(errors, :to_a).to include expected
        end
      end

      describe 'with data' do
        let(:expected) do
          {
            data:    { min: 0, max: 10 },
            message: nil,
            path:    [],
            type:    'some_error'
          }
        end

        it { expect(errors.add 'some_error', min: 0, max: 10).to be errors }

        it 'should add the error' do
          expect { errors.add 'some_error', min: 0, max: 10 }
            .to change(errors, :to_a).to include expected
        end
      end
    end
  end

  describe '#dig' do
    let(:error_message) { 'key must be an Integer, a String or a Symbol' }

    it 'should define the method' do
      expect(errors)
        .to respond_to(:dig)
        .with(1).argument
        .and_unlimited_arguments
    end

    describe 'with nil' do
      it 'should raise an error' do
        expect { errors.dig(nil) }.to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { errors.dig(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an integer' do
      let(:cached) { errors.dig(1) }

      it { expect(errors.dig(1)).to be == described_class.new }

      it { expect(errors.dig(1)).to be cached }

      it { expect(errors.dig(1)).to be errors[1] }
    end

    describe 'with a string' do
      let(:cached) { errors.dig('potions') }

      it { expect(errors.dig('potions')).to be == described_class.new }

      it { expect(errors.dig('potions')).to be cached }

      it { expect(errors.dig('potions')).to be errors[:potions] }
    end

    describe 'with a symbol' do
      let(:cached) { errors.dig(:potions) }

      it { expect(errors.dig(:potions)).to be == described_class.new }

      it { expect(errors.dig(:potions)).to be cached }

      it { expect(errors.dig(:potions)).to be errors[:potions] }
    end

    describe 'with multiple items' do
      let(:cached) { errors.dig(:cities, 0, :item_shops, 0) }

      it 'should be an empty errors object' do
        expect(errors.dig(:cities, 0, :item_shops, 0))
          .to be == described_class.new
      end

      it { expect(errors.dig(:cities, 0, :item_shops, 0)).to be cached }

      it 'should access the nested errors object' do
        expect(errors.dig(:cities, 0, :item_shops, 0))
          .to be errors[:cities][0][:item_shops][0]
      end
    end

    describe 'with an empty array' do
      it { expect(errors.dig([])).to be errors }
    end

    describe 'with an array with nil' do
      it 'should raise an error' do
        expect { errors.dig([nil]) }.to raise_error ArgumentError, error_message
      end
    end

    describe 'with an array with an Object' do
      it 'should raise an error' do
        expect { errors.dig([Object.new.freeze]) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an array with an integer' do
      let(:cached) { errors.dig([1]) }

      it { expect(errors.dig([1])).to be == described_class.new }

      it { expect(errors.dig([1])).to be cached }

      it { expect(errors.dig([1])).to be errors[1] }
    end

    describe 'with an array with a string' do
      let(:cached) { errors.dig(['potions']) }

      it { expect(errors.dig(['potions'])).to be == described_class.new }

      it { expect(errors.dig(['potions'])).to be cached }

      it { expect(errors.dig(['potions'])).to be errors[:potions] }
    end

    describe 'with an array with a symbol' do
      let(:cached) { errors.dig([:potions]) }

      it { expect(errors.dig([:potions])).to be == described_class.new }

      it { expect(errors.dig([:potions])).to be cached }

      it { expect(errors.dig([:potions])).to be errors[:potions] }
    end

    describe 'with an array with multiple items' do
      let(:cached) { errors.dig([:cities, 0, :item_shops, 0]) }

      it 'should be an empty errors object' do
        expect(errors.dig([:cities, 0, :item_shops, 0]))
          .to be == described_class.new
      end

      it { expect(errors.dig([:cities, 0, :item_shops, 0])).to be cached }

      it 'should access the nested errors object' do
        expect(errors.dig([:cities, 0, :item_shops, 0]))
          .to be errors[:cities][0][:item_shops][0]
      end
    end

    wrap_context 'when the errors has many child errors' do
      describe 'with a string that does not match an existing key' do
        let(:cached) { errors.dig('potions') }

        it { expect(errors.dig('potions')).to be == described_class.new }

        it { expect(errors.dig('potions')).to be cached }

        it { expect(errors.dig('potions')).to be errors[:potions] }
      end

      describe 'with a string that matches an existing key' do
        let(:cached) { errors.dig('spells') }
        let(:expected_errors) do
          expected_child_errors.map { |hsh| hsh.merge(path: []) }
        end

        it { expect(errors.dig('spells')).to be == expected_errors }

        it { expect(errors.dig('spells')).to be cached }

        it { expect(errors.dig('spells')).to be errors[:spells] }
      end

      describe 'with a symbol that does not match an existing key' do
        let(:cached) { errors.dig(:potions) }

        it { expect(errors.dig(:potions)).to be == described_class.new }

        it { expect(errors.dig(:potions)).to be cached }

        it { expect(errors.dig(:potions)).to be errors[:potions] }
      end

      describe 'with a symbol that matches an existing key' do
        let(:cached) { errors.dig(:spells) }
        let(:expected_errors) do
          expected_child_errors.map { |hsh| hsh.merge(path: []) }
        end

        it { expect(errors.dig(:spells)).to be == expected_errors }

        it { expect(errors.dig(:spells)).to be cached }

        it { expect(errors.dig(:spells)).to be errors[:spells] }
      end

      describe 'with an array that does not match an existing key' do
        let(:cached) { errors.dig([:potions]) }

        it { expect(errors.dig([:potions])).to be == described_class.new }

        it { expect(errors.dig([:potions])).to be cached }

        it { expect(errors.dig([:potions])).to be errors[:potions] }
      end

      describe 'with an array that matches an existing key' do
        let(:cached) { errors.dig([:spells]) }
        let(:expected_errors) do
          expected_child_errors.map { |hsh| hsh.merge(path: []) }
        end

        it { expect(errors.dig([:spells])).to be == expected_errors }

        it { expect(errors.dig([:spells])).to be cached }

        it { expect(errors.dig([:spells])).to be errors[:spells] }
      end
    end

    wrap_context 'when the errors has many deeply nested errors' do
      describe 'with a string that does not match an existing key' do
        let(:cached) { errors.dig('potions') }

        it { expect(errors.dig('potions')).to be == described_class.new }

        it { expect(errors.dig('potions')).to be cached }

        it { expect(errors.dig('potions')).to be errors[:potions] }
      end

      describe 'with a string that matches an existing key' do
        let(:cached) { errors.dig('guilds') }
        let(:expected_errors) do
          expected_nested_errors.map do |hsh|
            hsh.merge(path: hsh[:path][1..-1])
          end
        end

        it { expect(errors.dig('guilds')).to be == expected_errors }

        it { expect(errors.dig('guilds')).to be cached }

        it { expect(errors.dig('guilds')).to be errors[:guilds] }
      end

      describe 'with a symbol that does not match an existing key' do
        let(:cached) { errors.dig(:potions) }

        it { expect(errors.dig(:potions)).to be == described_class.new }

        it { expect(errors.dig(:potions)).to be cached }
      end

      describe 'with a symbol that matches an existing key' do
        let(:cached) { errors.dig(:guilds) }
        let(:expected_errors) do
          expected_nested_errors.map do |hsh|
            hsh.merge(path: hsh[:path][1..-1])
          end
        end

        it { expect(errors.dig(:guilds)).to be == expected_errors }

        it { expect(errors.dig(:guilds)).to be cached }

        it { expect(errors.dig(:guilds)).to be errors[:guilds] }
      end

      describe 'with multiple non-matching items' do
        let(:cached) { errors.dig(:cities, 0, :item_shops, 0) }

        it 'should be an empty errors object' do
          expect(errors.dig(:cities, 0, :item_shops, 0))
            .to be == described_class.new
        end

        it { expect(errors.dig(:cities, 0, :item_shops, 0)).to be cached }

        it 'should access the nested errors object' do
          expect(errors.dig(:cities, 0, :item_shops, 0))
            .to be errors[:cities][0][:item_shops][0]
        end
      end

      describe 'with multiple partially-matching items' do
        let(:cached) { errors.dig(:guilds, 3, :name) }

        it 'should be an empty errors object' do
          expect(errors.dig(:guilds, 3, :name))
            .to be == described_class.new
        end

        it { expect(errors.dig(:guilds, 3, :name)).to be cached }

        it 'should access the nested errors object' do
          expect(errors.dig(:guilds, 3, :name))
            .to be errors[:guilds][3][:name]
        end
      end

      describe 'with multiple matching items' do
        let(:cached) { errors.dig(:guilds, 2, :members) }

        let(:expected_errors) do
          expected_nested_errors
            .select { |err| err[:path][0...3] == [:guilds, 2, :members] }
            .map { |hsh| hsh.merge(path: hsh[:path][3..-1]) }
        end

        it { expect(errors.dig(:guilds, 2, :members)).to be == expected_errors }

        it { expect(errors.dig(:guilds, 2, :members)).to be cached }

        it 'should access the nested errors object' do
          expect(errors.dig(:guilds, 2, :members))
            .to be errors[:guilds][2][:members]
        end
      end

      describe 'with an array that does not match an existing key' do
        let(:cached) { errors.dig([:potions]) }

        it { expect(errors.dig([:potions])).to be == described_class.new }

        it { expect(errors.dig([:potions])).to be cached }

        it { expect(errors.dig([:potions])).to be errors[:potions] }
      end

      describe 'with an array that matches an existing key' do
        let(:cached) { errors.dig([:guilds]) }
        let(:expected_errors) do
          expected_nested_errors.map do |hsh|
            hsh.merge(path: hsh[:path][1..-1])
          end
        end

        it { expect(errors.dig([:guilds])).to be == expected_errors }

        it { expect(errors.dig([:guilds])).to be cached }

        it { expect(errors.dig([:guilds])).to be errors[:guilds] }
      end

      describe 'with an array with non-matching items' do
        let(:cached) { errors.dig([:cities, 0, :item_shops, 0]) }

        it 'should be an empty errors object' do
          expect(errors.dig([:cities, 0, :item_shops, 0]))
            .to be == described_class.new
        end

        it { expect(errors.dig([:cities, 0, :item_shops, 0])).to be cached }

        it 'should access the nested errors object' do
          expect(errors.dig([:cities, 0, :item_shops, 0]))
            .to be errors[:cities][0][:item_shops][0]
        end
      end

      describe 'with an array with partially-matching items' do
        let(:cached) { errors.dig([:guilds, 3, :name]) }

        it 'should be an empty errors object' do
          expect(errors.dig([:guilds, 3, :name]))
            .to be == described_class.new
        end

        it { expect(errors.dig([:guilds, 3, :name])).to be cached }

        it 'should access the nested errors object' do
          expect(errors.dig([:guilds, 3, :name]))
            .to be errors[:guilds][3][:name]
        end
      end

      describe 'with an array with matching items' do
        let(:cached) { errors.dig([:guilds, 2, :members]) }

        let(:expected_errors) do
          expected_nested_errors
            .select { |err| err[:path][0...3] == [:guilds, 2, :members] }
            .map { |hsh| hsh.merge(path: hsh[:path][3..-1]) }
        end

        it 'should return the filtered errors' do
          expect(errors.dig([:guilds, 2, :members])).to be == expected_errors
        end

        it { expect(errors.dig([:guilds, 2, :members])).to be cached }

        it 'should access the nested errors object' do
          expect(errors.dig([:guilds, 2, :members]))
            .to be errors[:guilds][2][:members]
        end
      end
    end

    wrap_context 'when the errors has many indexed errors' do
      describe 'with an integer that does not match an existing key' do
        let(:cached) { errors.dig(3) }

        it { expect(errors.dig(3)).to be == described_class.new }

        it { expect(errors.dig(3)).to be cached }

        it { expect(errors.dig(3)).to be errors[3] }
      end

      describe 'with an integer that matches an existing key' do
        let(:cached) { errors.dig(1) }
        let(:expected_errors) do
          [expected_indexed_errors[1].merge(path: [])]
        end

        it { expect(errors.dig(1)).to be == expected_errors }

        it { expect(errors.dig(1)).to be cached }

        it { expect(errors.dig(1)).to be errors[1] }
      end

      describe 'with an array that does not match an existing key' do
        let(:cached) { errors.dig([3]) }

        it { expect(errors.dig([3])).to be == described_class.new }

        it { expect(errors.dig([3])).to be cached }

        it { expect(errors.dig([3])).to be errors[3] }
      end

      describe 'with an array that matches an existing key' do
        let(:cached) { errors.dig([1]) }
        let(:expected_errors) do
          [expected_indexed_errors[1].merge(path: [])]
        end

        it { expect(errors.dig([1])).to be == expected_errors }

        it { expect(errors.dig([1])).to be cached }

        it { expect(errors.dig([1])).to be errors[1] }
      end
    end
  end

  describe '#dup' do
    it { expect(errors).to respond_to(:dup).with(0).arguments }

    it { expect(errors.dup).to be == errors }

    it { expect(errors.dup.to_a).to contain_exactly(*expected_errors) }

    it 'should create a copy of the errors' do
      expect { errors.dup.add(:some_error) }.not_to change(errors, :size)
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the errors has many root errors' do
      it { expect(errors.dup).to be == errors }

      it { expect(errors.dup.to_a).to contain_exactly(*expected_errors) }

      it 'should create a copy of the errors' do
        expect { errors.dup.add(:some_error) }.not_to change(errors, :size)
      end
    end

    wrap_context 'when the errors has many child errors' do
      it { expect(errors.dup).to be == errors }

      it { expect(errors.dup.to_a).to contain_exactly(*expected_errors) }

      it 'should create a copy of the errors' do
        expect { errors.dup.add(:some_error) }.not_to change(errors, :size)
      end
    end

    wrap_context 'when the errors has many deeply nested errors' do
      it { expect(errors.dup).to be == errors }

      it { expect(errors.dup.to_a).to contain_exactly(*expected_errors) }

      it 'should create a copy of the errors' do
        expect { errors.dup.add(:some_error) }.not_to change(errors, :size)
      end
    end

    wrap_context 'when the errors has many errors at different paths' do
      it { expect(errors.dup).to be == errors }

      it { expect(errors.dup.to_a).to contain_exactly(*expected_errors) }

      it 'should create a copy of the errors' do
        expect { errors.dup.add(:some_error) }.not_to change(errors, :size)
      end
    end

    wrap_context 'when the errors has many indexed errors' do
      it { expect(errors.dup).to be == errors }

      it { expect(errors.dup.to_a).to contain_exactly(*expected_errors) }

      it 'should create a copy of the errors' do
        expect { errors.dup.add(:some_error) }.not_to change(errors, :size)
      end
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#each' do
    shared_examples 'should yield each error' do
      describe 'with no arguments' do
        let(:enumerator) { errors.each }

        it { expect(errors.each).to be_a Enumerator }

        it { expect(enumerator.size).to be errors.size }

        it 'should yield each error' do
          yielded = []

          enumerator.each { |error| yielded << error }

          expect(yielded).to contain_exactly(*expected_errors)
        end
      end

      describe 'with a block' do
        it 'should yield each error' do
          yielded = []

          errors.each { |error| yielded << error }

          expect(yielded).to contain_exactly(*expected_errors)
        end
      end
    end

    it { expect(errors).to respond_to(:each).with(0).arguments }

    describe 'with no arguments' do
      let(:enumerator) { errors.each }

      it { expect(errors.each).to be_a Enumerator }

      it { expect(enumerator.size).to be 0 }

      it 'should not yield control' do
        expect { |block| enumerator.each(&block) }.not_to yield_control
      end
    end

    describe 'with a block' do
      it 'should not yield control' do
        expect { |block| errors.each(&block) }.not_to yield_control
      end
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the errors has many root errors' do
      include_examples 'should yield each error'
    end

    wrap_context 'when the errors has many child errors' do
      include_examples 'should yield each error'
    end

    wrap_context 'when the errors has many deeply nested errors' do
      include_examples 'should yield each error'
    end

    wrap_context 'when the errors has many errors at different paths' do
      include_examples 'should yield each error'
    end

    wrap_context 'when the errors has many indexed errors' do
      include_examples 'should yield each error'
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#empty?' do
    it { expect(errors).to respond_to(:empty?).with(0).arguments }

    it { expect(errors).to alias_method(:empty?).as(:blank?) }

    it { expect(errors.empty?).to be true }

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the errors has many root errors' do
      it { expect(errors.empty?).to be false }
    end

    wrap_context 'when the errors has many child errors' do
      it { expect(errors.empty?).to be false }
    end

    wrap_context 'when the errors has many deeply nested errors' do
      it { expect(errors.empty?).to be false }
    end

    wrap_context 'when the errors has many errors at different paths' do
      it { expect(errors.empty?).to be false }
    end

    wrap_context 'when the errors has many indexed errors' do
      it { expect(errors.empty?).to be false }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#eql?' do
    let(:method_name) { :eql? }

    include_examples 'should determine the equality'
  end

  describe '#merge' do
    shared_examples 'should dup and update the errors' do
      let(:expected_errors) do
        super() + expected_other_errors
      end

      it { expect(errors.merge value).to be_a described_class }

      it { expect(errors.merge value).not_to be errors }

      it { expect { errors.merge value }.not_to change(errors, :to_a) }

      it { expect(errors.merge(value).size).to be expected_errors.size }

      it 'should merge the errors' do
        expect(errors.merge(value).to_a).to contain_exactly(*expected_errors)
      end
    end

    shared_examples 'should merge the errors' do
      describe 'with nil' do
        it 'should raise an error' do
          expect { errors.merge(nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Object' do
        it 'should raise an error' do
          expect { errors.merge(Object.new.freeze) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an empty Array' do
        let(:value) { [] }

        include_examples 'should dup and update the errors'
      end

      describe 'with an Array with nil' do
        it 'should raise an error' do
          expect { errors.merge([nil]) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Array with an object' do
        it 'should raise an error' do
          expect { errors.merge([Object.new.freeze]) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Array with an invalid Hash' do
        it 'should raise an error' do
          expect { errors.merge([{}]) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Array of errors hashes' do
        include_context 'with another errors object'

        let(:value) { other_errors.to_a }

        include_examples 'should dup and update the errors'
      end

      describe 'with an empty errors object' do
        let(:value) { described_class.new }

        include_examples 'should dup and update the errors'
      end

      describe 'with an errors object' do
        include_context 'with another errors object'

        let(:value) { other_errors }

        include_examples 'should dup and update the errors'
      end
    end

    let(:error_message) do
      'value must be an instance of Stannum::Errors or an array of error' \
      ' hashes'
    end
    let(:expected_other_errors) { [] }

    it { expect(errors).to respond_to(:merge).with(1).argument }

    include_examples 'should merge the errors'

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the errors has many root errors' do
      include_examples 'should merge the errors'
    end

    wrap_context 'when the errors has many child errors' do
      include_examples 'should merge the errors'
    end

    wrap_context 'when the errors has many deeply nested errors' do
      include_examples 'should merge the errors'
    end

    wrap_context 'when the errors has many errors at different paths' do
      include_examples 'should merge the errors'
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#size' do
    it { expect(errors).to respond_to(:size).with(0).arguments }

    it { expect(errors).to alias_method(:size).as(:count) }

    it { expect(errors.size).to be 0 }

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the errors has many root errors' do
      it { expect(errors.size).to be expected_errors.size }
    end

    wrap_context 'when the errors has many child errors' do
      it { expect(errors.size).to be expected_errors.size }
    end

    wrap_context 'when the errors has many deeply nested errors' do
      it { expect(errors.size).to be expected_errors.size }
    end

    wrap_context 'when the errors has many errors at different paths' do
      it { expect(errors.size).to be expected_errors.size }
    end

    wrap_context 'when the errors has many indexed errors' do
      it { expect(errors.size).to be expected_errors.size }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#to_a' do
    it { expect(errors).to respond_to(:to_a).with(0).arguments }

    it { expect(errors.to_a).to be == [] }

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the errors has many root errors' do
      it { expect(errors.to_a).to contain_exactly(*expected_errors) }
    end

    wrap_context 'when the errors has many child errors' do
      it { expect(errors.to_a).to contain_exactly(*expected_errors) }
    end

    wrap_context 'when the errors has many deeply nested errors' do
      it { expect(errors.to_a).to contain_exactly(*expected_errors) }
    end

    wrap_context 'when the errors has many errors at different paths' do
      it { expect(errors.to_a).to contain_exactly(*expected_errors) }
    end

    wrap_context 'when the errors has many indexed errors' do
      it { expect(errors.to_a).to contain_exactly(*expected_errors) }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#update' do
    shared_examples 'should update the errors in place' do
      let(:expected_errors) do
        super() + expected_other_errors
      end

      it { expect(errors.update value).to be errors }

      it { expect(errors.update(value).size).to be expected_errors.size }

      it 'should update the errors' do
        errors.update value

        expect(errors.to_a).to contain_exactly(*expected_errors)
      end
    end

    shared_examples 'should update the errors' do
      describe 'with nil' do
        it 'should raise an error' do
          expect { errors.update(nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Object' do
        it 'should raise an error' do
          expect { errors.update(Object.new.freeze) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an empty Array' do
        let(:value) { [] }

        include_examples 'should update the errors in place'
      end

      describe 'with an Array with nil' do
        it 'should raise an error' do
          expect { errors.update([nil]) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Array with an object' do
        it 'should raise an error' do
          expect { errors.update([Object.new.freeze]) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Array with an invalid Hash' do
        it 'should raise an error' do
          expect { errors.update([{}]) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Array of errors hashes' do
        include_context 'with another errors object'

        let(:value) { other_errors.to_a }

        include_examples 'should update the errors in place'
      end

      describe 'with an empty errors object' do
        let(:value) { described_class.new }

        include_examples 'should update the errors in place'
      end

      describe 'with an errors object' do
        include_context 'with another errors object'

        let(:value) { other_errors }

        include_examples 'should update the errors in place'
      end
    end

    let(:error_message) do
      'value must be an instance of Stannum::Errors or an array of error' \
      ' hashes'
    end
    let(:expected_other_errors) { [] }

    it { expect(errors).to respond_to(:update).with(1).argument }

    include_examples 'should update the errors'

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the errors has many root errors' do
      include_examples 'should update the errors'
    end

    wrap_context 'when the errors has many child errors' do
      include_examples 'should update the errors'
    end

    wrap_context 'when the errors has many deeply nested errors' do
      include_examples 'should update the errors'
    end

    wrap_context 'when the errors has many errors at different paths' do
      include_examples 'should update the errors'
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end
end
