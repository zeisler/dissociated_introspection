# Changelog
All notable changes to this project will be documented in this file.

## 0.4.0 - 2015-01-18
### Enhancement
- `RubyClass#module_nesting` returns an array of symbols representing the module namespacing that the class is within.

### Fix
- If a class was not found it could return all given code.

## 0.3.1 - 2015-01-17
### Enhancement
- `DissociatedIntrospection::RubyClass` now can take a `DissociatedIntrospection::RubyCode` which is build with `#build_from_ast`, `#build_from_source`.
- `DissociatedIntrospection::WrapInModules` given a instance of `DissociatedIntrospection::RubyCode` it will nest any depth of module namespacing.
