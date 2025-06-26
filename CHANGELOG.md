# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions workflow for automated testing against multiple Koha versions
- Comprehensive testing framework with version synchronization tests
- Modern version management with increment_version.js utility
- Automated KPZ creation using ByWater's official GitHub Actions
- CONTRIBUTING.md with development guidelines
- Documentation in docs/ directory (INSTALLATION.md, ORACLE_INTEGRATION.md)
- npm scripts for version management and releases
- Support for semantic versioning workflow

### Changed
- **REBRANDING**: Migrated from PTFS Europe to Open Fifth organization
- **Plugin namespace**: Updated from `Koha::Plugin::Com::PTFSEurope::Oracle` to `Koha::Plugin::Com::OpenFifth::Oracle`
- **Directory structure**: Moved from `PTFSEurope/` to `OpenFifth/` directory structure
- **Repository URLs**: Updated all GitHub URLs to openfifth organization
- **Author attribution**: Changed from 'PTFS Europe' to 'Open Fifth'
- Modernized build process to use auto-release template integration
- Updated package.json with proper plugin configuration and scripts
- Enhanced cron job to handle empty invoice sets gracefully
- Fixed GL line generation to properly handle order quantities
- Improved error handling for automated scheduling

### Fixed
- GL lines now correctly generate one line per quantity unit
- Invoice total calculation now properly multiplies unitprice by quantity
- Cron job returns early when no invoices found, preventing empty file creation

### Removed
- Legacy build scripts (release_kpz.sh, checkVersionNumber.js, checkRemotes.js, gulpfile.js)
- Obsolete Gulp-based build system
- Manual version management workflow

## [0.0.21] - 2024-11-15

### Fixed
- Use tax included pricing for accurate Oracle integration
- Corrected pricing calculations for finance system compatibility

### Changed
- Updated plugin metadata and version information

## [0.0.20] - Previous releases

### Added
- Initial Oracle finance integration functionality
- Support for RBKC supplier filtering
- Fund code mapping to Oracle cost centers and supplier numbers
- Automated file generation with proper naming convention
- Support for both local file output and transport upload
- Configurable scheduling for automated processing
- Manual report generation with date range selection
- Tax code mapping based on tax rates

### Features
- **Invoice Processing**: Exports invoices from RBKC suppliers
- **File Format**: Generates CT (Control Total), AP (Accounts Payable), and GL (General Ledger) records
- **Scheduling**: Configurable days for automated nightly processing
- **Transport**: Support for automated file upload via Koha file transports
- **Mapping**: Hardcoded fund code mappings for RBKC cost centers and supplier numbers
- **Configuration**: Web interface for transport and scheduling configuration

---

## Release Process

Starting with version 0.0.22, releases follow the modern auto-release workflow:

1. Use `npm run release:patch|minor|major` for version management
2. GitHub Actions automatically tests against Koha main, stable, and oldstable
3. KPZ files are created automatically for releases
4. Release notes are generated from this CHANGELOG.md