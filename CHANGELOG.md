# Changelog
All notable changes to this project will be documented in this file.

## 0.3.0 - 2015-01-17
### Enhancement
- `DissociatedIntrospection::RubyClass` now can take a `DissociatedIntrospection::RubyCode` which is build with `#build_from_ast`, `#build_from_source`.
- `DissociatedIntrospection::WrapInModules` given a instance of `DissociatedIntrospection::RubyCode` it will nest any depth of module namespacing.
