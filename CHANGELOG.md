# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Plugin install lifecycle: `install`/`uninstall`/`upgrade` methods now create and drop the `plugin_oracle_submitted_invoices` table, bringing the plugin in line with the sibling SAP and WSCC Oracle plugins
- Invoice submission deduplication: the nightly cron and the manual SFTP/save buttons now record successfully submitted invoices in `plugin_oracle_submitted_invoices`, and the cron excludes already-submitted invoices on subsequent runs to prevent duplicate uploads
- "Manage submitted invoices" sidebar link on the report page and a new `manage-submissions.tt` UI for viewing the submission log and selectively allowing resubmission of specific invoices
- Warning banner on the HTML report preview when invoices in the chosen date range have already been submitted
- Test coverage for the new install/uninstall/upgrade lifecycle and submission-tracking helpers in `01-oracle-integration.t`

## [0.2.2] - 2026-05-06

### Changed

- Configuration page: merge Output and Transport into a single fieldset with Transport as a nested sub-fieldset; render Run days checkboxes horizontally instead of vertically in their own top-level fieldset
- Configuration page: add an explicit "-- None --" option to the Transport server select so an unconfigured state is no longer misrepresented by the first listed transport appearing selected by default

### Fixed

- Configuration page: persist the selected Transport server correctly on re-render — the previous `transport_server.id` comparison against a scalar id always evaluated false, so the saved transport was never marked `selected`
- Configuration page: rename the Output select's id from `output` to `report_output` to avoid a CSS clash with an upstream Koha rule on `#output`

## [0.2.1] - 2026-05-06

### Changed
- Clarify on the configuration page that Transport settings are unused when Output is set to "Local file" — the Transport fieldset is now disabled and an explanation describes the pull-vs-push model

## [0.2.0] - 2026-03-04

### Added
- Logging for the nightly cronjob via `Koha::Logger`

## [0.1.2] - 2026-03-03

### Changed
- Seed fund mappings in integration tests

## [0.1.1] - 2026-03-03

Release housekeeping only — no functional changes.

## [0.1.0] - 2026-03-03

### Added
- UI-driven fund mappings configuration on the configuration page, replacing the previous hardcoded fund-to-cost-center/supplier-account mappings

## [0.0.49] - 2025-11-13

### Fixed
- Declare `$invoice_total` variable with `my` to satisfy strict mode

## [0.0.48] - 2025-11-13

### Changed
- Pin the GitHub Actions workflows to a single image and branch

## [0.0.47] - 2025-11-13

### Added
- "Round Last" AP calculation for Oracle validation

## [0.0.46] - 2025-11-05

### Fixed
- Use exact EDI amounts for adjustments to preserve supplier data integrity — parse `EDI_EXCL` values from adjustment notes (MOA+8 segments) instead of back-calculating tax-exclusive from tax-inclusive, falling back to calculation only for legacy adjustments

## [0.0.45] - 2025-10-08

### Fixed
- Correct `Koha::Number::Price` usage to output integer pence

## [0.0.44] - 2025-10-08

### Fixed
- Implement HMRC-compliant rounding and the "Round Last" principle — keep full precision through intermediate calculations and round half-up only at CSV export

## [0.0.43] - 2025-10-06

### Fixed
- Round adjustment amounts to integer pence

## [0.0.42] - 2025-10-03

### Fixed
- Calculate tax-included adjustment amounts for the AP total when the `CalculateFundValuesIncludingTax` syspref is FALSE

### Changed
- Codebase tidy

## [0.0.41] - 2025-10-03

### Fixed
- Parse service charge tax rates from adjustment notes

## [0.0.40] - 2025-10-01

### Fixed
- Further corrections for ticket 131752 tax changes

## [0.0.39] - 2025-09-30

### Fixed
- Additional corrections for ticket 131752 tax changes

## [0.0.38] - 2025-09-30

### Fixed
- AP header lines now use tax-inclusive totals while GL ledger lines use tax-exclusive amounts (ticket 131752)

## [0.0.37] - 2025-08-28

### Fixed
- Additional mapping correction follow-up to v0.0.36

## [0.0.36] - 2025-08-26

### Fixed
- Correct line ordering in CSV output — AP lines were appearing after GL lines instead of before
- Correct mapping order for the analysis field addition

## [0.0.35] - 2025-08-26

_No changes - accidental release tag._

## [0.0.34] - 2025-08-21

### Fixed
- Fix field miscount for GL records
- Prevent wasteful GitHub Actions runs

## [0.0.33] - 2025-08-20

### Fixed
- Resolve 'true' error using Mojo::JSON->true instead of literal 'true' string

## [0.0.32] - 2025-08-19

### Fixed
- Resolve 403 permissions error for upload/save functionality by adding API endpoint

### Refactored
- Replace tool method with proper API endpoint architecture
- Implement dedicated `/api/v1/contrib/oracle/upload` endpoint for upload operations
- Add OpenAPI 2.0 specification for upload endpoint documentation
- Create UploadController class following Koha plugin API patterns
- Remove unwanted tool page creation in favor of clean API interface

## [0.0.31] - 2025-08-19

### Added
- Text::CSV integration for proper CSV formatting and validation
- Robust CSV generation with correct escaping of special characters
- Enhanced download functionality with standards-compliant CSV output
- New `sftp_upload` method with configuration-aware upload/save logic
- Modern Bootstrap UI with cards, badges, and professional styling
- AJAX upload/save functionality with loading states and error handling
- Smart buttons that adapt to configuration (SFTP upload vs local save)
- Scrollable report preview with monospace formatting
- Dynamic button labels based on output configuration

### Changed
- Replace manual string concatenation with Text::CSV writer
- Convert CSV rows to array references for better maintainability
- Improve code structure and standards compliance
- Enhanced report template with modern design patterns
- Update UI to match WSCC template styling and functionality
- Improve user experience with better visual feedback

### Fixed
- Improve adjustment matching for split orders
- Proper handling of quotes, commas, and special characters in CSV output
- Enhanced error handling with user-friendly messages
- Better template parameter passing for UI functionality

## [0.0.30] - 2025-08-19

### Fixed
- Update unit tests to reflect recent code changes
- Test method rename from `_map_fund_to_suppliernumber` to `_map_fund_to_supplier_account`
- Add test coverage for new `_map_fund_to_analysis` method

## [0.0.29] - 2025-08-19

### Added
- Analysis field in Oracle integration format (field 9 in GL records)
- New `_map_fund_to_analysis()` method returning 'analysis' for all funds

### Changed
- Renamed `_map_fund_to_suppliernumber()` to `_map_fund_to_supplier_account()` for clarity
- Updated Oracle integration format with correct field positioning
- Improved variable naming to better match content
- Updated ORACLE_INTEGRATION.md documentation to match new 24-field specification

### Fixed
- Correct field positioning in AP and GL record types
- Proper separation of supplier account vs supplier number fields

## [0.0.27] - 2024-12-XX

### Fixed
- Correct tax code for adjustments
- Clean up superfluous database handle
- Fix branch reference from 'master' to 'main'

## [0.0.26] - 2024-12-XX

### Fixed
- Add fixed tax code for service charges

## [0.0.25] - 2024-12-XX

### Added
- Invoice adjustments to Oracle report

## [0.0.24] - 2024-12-XX

### Added
- package-lock.json for dependency management

## [0.0.23] - 2024-12-XX

### Changed
- Fix tests and CI configuration
- Use OpenFifth WCC Koha branch for testing
- Use OpenFifth Koha branch for testing

## [0.0.22] - 2024-11-XX

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

[Unreleased]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.2.2...HEAD
[0.2.2]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.49...v0.1.0
[0.0.49]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.48...v0.0.49
[0.0.48]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.47...v0.0.48
[0.0.47]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.46...v0.0.47
[0.0.46]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.45...v0.0.46
[0.0.45]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.44...v0.0.45
[0.0.44]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.43...v0.0.44
[0.0.43]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.42...v0.0.43
[0.0.42]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.41...v0.0.42
[0.0.41]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.40...v0.0.41
[0.0.40]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.39...v0.0.40
[0.0.39]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.38...v0.0.39
[0.0.38]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.37...v0.0.38
[0.0.37]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.36...v0.0.37
[0.0.36]: https://github.com/openfifth/koha-plugin-rbkc-oracle/compare/v0.0.35...v0.0.36