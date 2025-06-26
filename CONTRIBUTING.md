# Contributing to Koha Plugin RBKC Oracle

We welcome contributions to the RBKC Oracle Finance Integration plugin! This document provides guidelines for contributing to the project.

## Development Setup

### Prerequisites

- Node.js (for version management and testing)
- Perl 5.20+ with required Koha modules
- Git for version control
- Access to Koha testing environment

### Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/koha-plugin-rbkc-oracle.git
   cd koha-plugin-rbkc-oracle
   ```

3. Install development dependencies:
   ```bash
   npm install
   ```

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run tests with verbose output
npm run test:verbose

# Run specific test file
prove -v t/00-load.t
```

### Test Structure

- `t/00-load.t` - Basic module loading and version synchronization tests
- `t/01-oracle-integration.t` - Plugin-specific functionality tests

### Writing Tests

- Use modern Perl testing with `Test::More` and `Test::Exception`
- Test both success and failure scenarios
- Include tests for new mapping functions or configuration changes
- Ensure version synchronization tests pass

## Version Management

### Semantic Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality in backward-compatible manner  
- **PATCH**: Backward-compatible bug fixes

### Version Commands

```bash
# Increment patch version (0.0.1 -> 0.0.2)
npm run version:patch

# Increment minor version (0.1.0 -> 0.2.0)
npm run version:minor

# Increment major version (1.0.0 -> 2.0.0)
npm run version:major
```

## Release Process

### Creating a Release

1. Ensure all tests pass:
   ```bash
   npm test
   ```

2. Update version and create release:
   ```bash
   # For bug fixes
   npm run release:patch
   
   # For new features
   npm run release:minor
   
   # For breaking changes
   npm run release:major
   ```

3. The automated workflow will:
   - Update version in `package.json` and `Oracle.pm`
   - Update `date_updated` in plugin metadata
   - Commit changes and create git tag
   - Push to GitHub with tags
   - Trigger GitHub Actions for testing and KPZ creation

### Release Workflow

- GitHub Actions automatically tests against Koha main, stable, and oldstable
- KPZ files are created automatically for releases
- Release notes are generated from CHANGELOG.md

## Code Guidelines

### Perl Code Style

- Use `Modern::Perl` pragma
- Follow existing indentation and naming conventions
- Use meaningful variable and method names
- Add comments for complex business logic

### Plugin Structure

- Main plugin logic in `Oracle.pm`
- Template files in `Oracle/` subdirectory
- Configuration handled through Koha plugin framework
- Use Koha's standard database access patterns

### Oracle Integration

- Fund code mappings are hardcoded for RBKC requirements
- GL lines must be generated per quantity unit
- File format follows Oracle finance system specifications
- Support both local file output and transport upload

## Specific Areas

### Data Mapping

When updating fund code mappings:

1. Update both `_map_fund_to_costcenter()` and `_map_fund_to_suppliernumber()`
2. Add test cases for new mappings
3. Document the business reason for mapping changes

### File Format Changes

Oracle file format changes require:

1. Understanding of Oracle finance system requirements
2. Coordination with RBKC finance team
3. Thorough testing with sample data
4. Update of any related documentation

### Scheduled Processing

Cron job functionality should:

1. Handle empty result sets gracefully
2. Support configurable scheduling
3. Provide adequate error handling and logging
4. Support both file output and transport upload

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes with appropriate tests
3. Ensure all tests pass
4. Update documentation if needed
5. Submit pull request with clear description

### PR Requirements

- [ ] Tests pass locally
- [ ] New tests added for new functionality
- [ ] Documentation updated if needed
- [ ] Version synchronization maintained
- [ ] Clear commit messages

## Bug Reports

When reporting bugs, please include:

- Koha version
- Plugin version
- Steps to reproduce
- Expected vs actual behavior
- Error messages or logs
- Sample data (if safe to share)

## Feature Requests

For new features:

- Describe the business need
- Explain expected behavior
- Consider impact on existing functionality
- Discuss Oracle integration requirements

## Getting Help

- Create an issue for questions
- Check existing issues and documentation
- Contact Open Fifth for RBKC-specific requirements

## License

By contributing, you agree that your contributions will be licensed under the GPL-3.0 license.