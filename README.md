# Dissociated Introspection
[![Build Status](https://travis-ci.org/zeisler/dissociated_introspection.svg?branch=master)](https://travis-ci.org/zeisler/dissociated_introspection)
[![Code Climate](https://codeclimate.com/github/zeisler/dissociated_introspection/badges/gpa.svg)](https://codeclimate.com/github/zeisler/dissociated_introspection)
[![Test Coverage](https://codeclimate.com/github/zeisler/dissociated_introspection/badges/coverage.svg)](https://codeclimate.com/github/zeisler/dissociated_introspection/coverage)

Introspect methods, parameters, class macros, and constants without loading a parent class or any other dependencies.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dissociated_introspection'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dissociated_introspection

## Usage

### Static Analysis

```ruby
ruby_class_as_str <<-RUBY
  class A < B::C
    def method1(arg)
    end
  end
RUBY

ruby_class = DissociatedIntrospection::RubyClass.new(source: ruby_class_as_str)
ruby_class.class_name
    # => "A" 
    
ruby_class.parent_class_name
    # => "B::C"
    
new_ruby_class = ruby_class.modify_parent_class(:C)
new_ruby_class.parent_class_name
    # => "C"
    
new_ruby_class.source
    # => "class A < C\n  def method\n  end\nend"
    
ruby_class.defs.first.name
    # => :method1

ruby_class.defs.first.arguments
    # => "arg"
```

### Sandboxed Analysis

```ruby
# app/model/user.rb
class User < ActiveRecord::Base
  attr_accessor :baz
  scope :recent_users, -> { 'some SQL' }
  include UserHelpers
  def display_name
    "#{first_name} #{last_name}"
  end
end
```

ActiveRecord does not need to be loaded, it will be replaced with an alternate.

```ruby
inspection = DissociatedIntrospection::Inspection.new(file: user_model_file)

inspection.class_macros
    # => [{ attr_accessor: [[:baz]]},
          { scope: [[:recent_users], #<Proc:0x0> ] },
          { include: [[#<Module:0x0>]]}]
          
inspection.missing_constants
    # => { UserHelpers: #<Module:0x0> }
    
# Removes meta-programmed methods from ActiveRecord
inspection.get_class.instance_methods(false)
    # => [ :method1 ]

```
## Other methods
* `DissociatedIntrospection::Inspection#extended_modules`
* `DissociatedIntrospection::Inspection#included_modules`
* `DissociatedIntrospection::Inspection#prepend_modules`
* `DissociatedIntrospection::Inspection#locally_defined_constants`

## Development

Run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/dissociated_introspection/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
