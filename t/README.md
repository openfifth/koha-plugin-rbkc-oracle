# Testing

This directory contains the test suite for the RBKC Oracle Finance Integration plugin.

## Test Files

- **00-load.t**: Basic module loading and version synchronization tests
- **01-oracle-integration.t**: Plugin-specific functionality and integration tests

## Running Tests

### Local Testing

```bash
# Run all tests
npm test

# Run tests with verbose output
npm run test:verbose

# Run specific test file
prove -v t/00-load.t
prove -v t/01-oracle-integration.t
```

### CI Testing

Tests are automatically run via GitHub Actions against multiple Koha versions:
- main (development)
- stable (current release)
- oldstable (previous release)

## Test Environment Requirements

### For Local Testing
- Koha development environment
- Required Perl modules: Test::More, Test::Exception
- JSON::MaybeXS, Path::Tiny

### For CI Testing
- Uses koha-testing-docker for consistent environment
- Automatically installs required dependencies
- Tests plugin loading and basic functionality

## Writing Tests

When adding new functionality:

1. **Add unit tests** for new methods in existing test files
2. **Test version synchronization** - ensure package.json and .pm versions match
3. **Test error conditions** as well as success cases
4. **Use descriptive test names** and group related tests in subtests

### Test Structure

```perl
use Modern::Perl;
use Test::More;
use Test::Exception;

# Basic tests
subtest 'Feature name' => sub {
    plan tests => 3;
    
    is($result, $expected, 'Descriptive test name');
    ok($condition, 'Boolean test description');
    like($string, qr/pattern/, 'Pattern matching test');
};
```

## Coverage

Tests should cover:
- ✅ Module loading
- ✅ Version synchronization
- ✅ Fund mapping functions
- ✅ Filename generation
- ✅ Configuration handling
- ✅ Cron parameter handling
- ✅ Plugin metadata validation

## Debugging

For test debugging:
- Use `prove -v` for verbose output
- Add `diag()` statements for debugging information
- Check Koha logs when testing with full environment