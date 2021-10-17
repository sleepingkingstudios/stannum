# frozen_string_literal: true

{
  en: {
    stannum: {
      constraints: {
        absent: 'is nil or empty',
        anything: 'is a value',
        does_not_have_methods: 'does not respond to the methods',
        has_methods: 'responds to the methods',
        hashes: {
          extra_keys: 'has extra keys',
          is_not_string_or_symbol: 'is not a String or a Symbol',
          is_string_or_symbol: 'is a String or a Symbol',
          no_extra_keys: 'does not have extra keys'
        },
        invalid: 'is invalid',
        is_boolean: 'is true or false',
        is_in_list: 'is in the list',
        is_in_union: 'matches one of the constraints',
        is_equal_to: 'is equal to',
        is_not_boolean: 'is not true or false',
        is_not_equal_to: 'is not equal to',
        is_not_in_list: 'is not in the list',
        is_not_in_union: 'does not match any of the constraints',
        is_not_type: lambda do |_type, data|
          if data[:required]
            "is not a #{data[:type]}"
          else
            "is not a #{data[:type]} or nil"
          end
        end,
        is_not_value: 'is not the expected value',
        is_type: lambda do |_type, data|
          if data[:required]
            "is a #{data[:type]}"
          else
            "is a #{data[:type]} or nil"
          end
        end,
        is_value: 'is the expected value',
        parameters: {
          extra_arguments: 'has extra arguments',
          extra_keywords: 'has extra keywords'
        },
        tuples: {
          extra_items: 'has extra items',
          no_extra_items: 'does not have extra items'
        },
        types: {
          is_nil: 'is nil',
          is_not_nil: 'is not nil'
        },
        present: 'is not nil or empty',
        valid: 'is valid'
      }
    }
  }
}
