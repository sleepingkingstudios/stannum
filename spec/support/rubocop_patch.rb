# frozen_string_literal: true

def insert_selectors(set, *values)
  set.send(:selectors).concat(values)
end

groups    = %i[wrap_context wrap_examples]
skipped   = %i[xwrap_context xwrap_examples]
focused   = %i[fwrap_context fwrap_examples]

namespace = RuboCop::RSpec::Language::ExampleGroups
insert_selectors(namespace::GROUPS,  *groups)
insert_selectors(namespace::SKIPPED, *skipped)
insert_selectors(namespace::FOCUSED, *focused)
insert_selectors(namespace::ALL,     *groups, *skipped, *focused)
insert_selectors(RuboCop::RSpec::Language::ALL, *groups, *skipped, *focused)

load 'rubocop/rspec/language/node_pattern.rb'
load 'rubocop/rspec/example_group.rb'
