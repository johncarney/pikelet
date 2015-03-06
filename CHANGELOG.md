## 2.0.0

### Enhancements

- Pikelet can now format records for output with:
    - custom field formatters, and/or
    - basic alignment and padding options.
- Signature fields can be arbitrarily named (legacy `type_signature` syntax
  will still work.)
- Custom record classes.

### Bug fixes

- Fixed a bug whereby fields with custom parsers would not be stripped of
  leading or trailing whitespace.

### Other changes

- Parsing of CSV files is no longer supported.
- Field indexes must be a range.

## 1.1.2

### Enhancements

- A parser block can now be declared as an option instead of a procedure
  block. This is for consistency with field formatters in an upcoming release.
  The old-style syntax will still work.

## 1.0.0

### Changes

- Field types are no supported.
- Removed dependency on Overpunch gem.
- Fields now only take a single field.

## 0.1.0

### Enhancements

- Field definitions can now accept a block for parsing field values.

### Deprecations

- Field types will be removed in a future release.

## 0.0.1

Initial release
