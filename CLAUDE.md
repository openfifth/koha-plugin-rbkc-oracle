# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Koha plugin for Oracle finance integration at RBKC (Royal Borough of Kensington and Chelsea). The plugin exports invoice data from Koha's acquisition system to Oracle's finance system.

## Architecture

### Plugin Structure

- **Main plugin file**: `Koha/Plugin/Com/OpenFifth/Oracle.pm` - Contains all plugin logic
- **Templates**: `Koha/Plugin/Com/OpenFifth/Oracle/` directory contains Template Toolkit files (.tt)
  - `configure.tt` - Plugin configuration interface
  - `report-step1.tt` - Date range selection for manual reports
  - `report-step2-html.tt` - HTML report output
  - `report-step2-txt.tt` - Text/CSV report output
- **Output directory**: `Koha/Plugin/Com/OpenFifth/Oracle/output/` - Local file storage

### Key Components

- **Configuration**: Transport settings, scheduled days, output method (local file vs upload)
- **Cronjob**: Automated nightly export based on configured schedule
- **Manual Reports**: Interactive report generation with date range selection
- **Data Mapping**: Fund codes mapped to cost centers and supplier numbers for Oracle
- **File Transport**: Integration with Koha::File::Transports for automated uploads

### Data Flow

1. Plugin queries invoices from RBKC suppliers (name LIKE 'RBKC%')
2. Generates three record types:
   - **CT** (Control Total) - Summary line with invoice count and total
   - **AP** (Accounts Payable) - One per invoice with supplier details
   - **GL** (General Ledger) - One per order line with fund/budget details
3. Exports as comma-separated format with Oracle-specific field mappings

## Development Commands

### Release Management

```bash
# Testing
npm test                    # Run all tests
npm run test:verbose        # Run tests with verbose output

# Version Management
npm run version:patch       # Increment patch version (0.0.21 -> 0.0.22)
npm run version:minor       # Increment minor version (0.1.0 -> 0.2.0)
npm run version:major       # Increment major version (1.0.0 -> 2.0.0)

# Releases (automated)
npm run release:patch       # Version bump + tag + push for patch release
npm run release:minor       # Version bump + tag + push for minor release
npm run release:major       # Version bump + tag + push for major release
```

### Automated Release Process

1. `npm run release:*` increments version in both package.json and Oracle.pm
2. Updates `date_updated` in plugin metadata
3. Commits changes with "chore: bump version" message
4. Creates version tag (v1.2.3) and pushes to GitHub
5. GitHub Actions workflow triggers automatically
6. Tests run against Koha main, stable, and oldstable versions
7. KPZ file is created automatically using ByWater's official action
8. GitHub release is created with KPZ artifact and CHANGELOG.md

### Version Synchronization

- Package.json and Oracle.pm versions are automatically synchronized
- `increment_version.js` utility handles both files simultaneously
- Tests verify version consistency between files
- Format: semantic versioning (major.minor.patch)

### File Structure for Koha Plugin

```
Koha/Plugin/Com/OpenFifth/Oracle.pm     # Main plugin class
Koha/Plugin/Com/OpenFifth/Oracle/       # Template and output directory
├── configure.tt                         # Configuration interface
├── report-step1.tt                      # Report date selection
├── report-step2-html.tt                 # HTML report display
├── report-step2-txt.tt                  # Text/CSV export format
└── output/                              # Local file output directory
```

## Key Methods in Oracle.pm

- `configure()` - Plugin configuration interface (transport settings, schedule)
- `cronjob_nightly()` - Automated export based on schedule configuration
- `report()` - Manual report interface dispatcher
- `report_step1()` - Date range selection form
- `report_step2()` - Report generation and output
- `_generate_report()` - Core logic for querying and formatting data
- `_map_fund_to_costcenter()` - Maps Koha fund codes to Oracle cost centers
- `_map_fund_to_suppliernumber()` - Maps fund codes to Oracle supplier numbers

## Data Mappings

The plugin contains hardcoded mappings for RBKC-specific fund codes to Oracle cost centers (E26xxx format) and supplier numbers (4-digit integers). These mappings are essential for proper Oracle integration and should be updated when RBKC changes their chart of accounts.

## Testing Framework

- **Unit Tests**: `t/00-load.t` - Module loading and version synchronization
- **Integration Tests**: `t/01-oracle-integration.t` - Plugin functionality and mapping tests
- **CI/CD**: GitHub Actions workflow tests against multiple Koha versions
- **Test Commands**: `npm test` for all tests, `npm run test:verbose` for detailed output

## Dependencies

### Runtime

- Koha 24.11.00.000+ (minimum version)
- Perl modules: Modern::Perl, Koha::Plugins::Base, Koha::DateUtils, etc.

### Development

- Node.js for version management and testing
- Required Perl test modules: Test::More, Test::Exception, JSON::MaybeXS, Path::Tiny

### CI/CD

- GitHub Actions for automated testing and releases
- ByWater's official KPZ creation action
- Docker-based koha-testing-docker for consistent test environment

