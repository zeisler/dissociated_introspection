# Changelog
All notable changes to this project will be documented in this file.

## 0.12.0 - 2018-08-02
### Enhancement
- MethodInLiner will now recursively in-lines methods.

## 0.11.0 - 2018-08-01
### Enhancement
- Ability to Inline local methods with the exception of ones with arguments passed.

## 0.10.0 - 2018-07-28
### Fix
- Require Ruby core lib resources. (Forwardable, Pathname)
- Deal with change in how Ruby order's it's constants.
### Enhancement
- RubyClass::Def methods return RubyCode object so that AST could be inspected
### Deprecation
- Dropping support for Ruby version 2.1

## 0.9.1 - 2018-01-16
### Fix
- `DissociatedIntrospection::RubyClass#class_begin` added back to public API

## 0.9.0 - 2018-01-16
### Enhancement
- `DissociatedIntrospection::RubyClass#defined_nested_modules` and #defined_nested_classes returns an array of `RubyCode`.
For any internally defined within the class it's self.


## 0.8.4 - 2017-09-30
### Fix
- `DissociatedIntrospection::RubyClass#class_defs` failed to parse a single class methods with `class >> self; end;`

## 0.8.3 - 2017-09-30
### Fix
- `DissociatedIntrospection::RubyClass#class_defs` failed to parse class methods with `class >> self; end;`

## 0.8.2 - 2017-06-23
### Enhancement
- Less strict parser version

## 0.8.1 - 2017-03-24
### Enhancement
- inspect_methods takes :instance_methods or :class_method/:methods to access #defs #class_defs

## 0.8.0 - 2017-03-24
### Enhancement
- `DissociatedIntrospection::RubyClass#class_defs` returns same api as #defs
- `DissociatedIntrospection::RubyClass#class_method_calls` inspect method name and its arguments ie. attr_reader :name

### Deprecated
 - `DissociatedIntrospection::RubyClass#is_class?` changed to `#class?`
 - `DissociatedIntrospection::RubyClass#has_parent_class?` changed to `#parent_class?`
 - `DissociatedIntrospection::RubyCode#to_ruby_str` changed to `#source`

## 0.7.1 - 2016-10-20
### Fix
- `DissociatedIntrospection::RubyClass#defs` fixed parse issue when class has one method.

## 0.7.0 - 2016-10-19
### Fix
- `DissociatedIntrospection::Inspection#parsed_source` now returns `RubyClass` with comments

## 0.6.0 - 2016-09-08
### Enhancement
- `DissociatedIntrospection::RubyClass#defs` now returns associated comments

## 0.5.0 - 2016-04-30
### Enhancement
- `DissociatedIntrospection.listen_to_defined_class_methods=` In addition to ruby methods like
attr_reader other DSL class methods can be recorded if specified.

## 0.4.1 - 2016-01-18
### Fix
- `RubyClass#module_nesting` could return modules that were nested inside of a class.

## 0.4.0 - 2016-01-18
### Enhancement
- `RubyClass#module_nesting` returns an array of symbols representing the module namespacing that the class is within.

### Fix
- If a class was not found it could return all given code.

## 0.3.1 - 2016-01-17
### Enhancement
- `DissociatedIntrospection::RubyClass` now can take a `DissociatedIntrospection::RubyCode` which is build with `#build_from_ast`, `#build_from_source`.
- `DissociatedIntrospection::WrapInModules` given a instance of `DissociatedIntrospection::RubyCode` it will nest any depth of module namespacing.
