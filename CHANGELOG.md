# Changelog
All notable changes to this project will be documented in this file.

## 0.7.1 - 2016-10-20
### Fix
- `DissociatedIntrospection::RubyClass#defs` fixed parse issue when class has one method.

## 0.7.0 - 2016-10-19
### Fix
- DissociatedIntrospection::Inspection#parsed_source now returns RubyClass with comments

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
