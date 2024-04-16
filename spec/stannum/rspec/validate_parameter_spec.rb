# frozen_string_literal: true

require 'stannum/rspec/validate_parameter'

RSpec.describe RSpec::Matchers do # rubocop:disable RSpec/FilePath, RSpec/SpecFilePathFormat
  let(:example_group) { Object.new.extend(Stannum::RSpec::Matchers) }

  describe '#validate_parameter' do
    let(:method_name)    { :call }
    let(:parameter_name) { :action }
    let(:matcher) do
      example_group.validate_parameter(method_name, parameter_name)
    end

    it 'should define the method' do
      expect(example_group)
        .to respond_to(:validate_parameter)
        .with(2).arguments
    end

    it { expect(matcher).to be_a Stannum::RSpec::ValidateParameterMatcher }

    it { expect(matcher.method_name).to be == method_name }

    it { expect(matcher.parameter_name).to be == parameter_name }

    it 'should set the description' do
      expect(matcher.description)
        .to be == "validate the #{parameter_name.inspect} parameter"
    end
  end
end
