# Installation Guide

## Prerequisites

- Koha 24.11.00.000 or later
- Perl modules (usually included with Koha):
  - Modern::Perl
  - Koha::Plugins::Base
  - Koha::DateUtils
  - Koha::File::Transports
  - Koha::Number::Price

## Installation Steps

### Method 1: KPZ File Installation (Recommended)

1. Download the latest KPZ file from the [Releases page](https://github.com/openfifth/koha-plugin-rbkc-oracle/releases)

2. In Koha staff interface:
   - Go to Home › Tools › Plugins
   - Click "Upload plugin"
   - Select the downloaded KPZ file
   - Click "Upload plugin"

3. Enable the plugin:
   - Find "Oracle Finance Integration" in the plugins list
   - Click "Actions" › "Enable"

### Method 2: Manual Installation

1. Clone or download the repository:
   ```bash
   git clone https://github.com/PTFS-Europe/koha-plugin-rbkc-oracle.git
   ```

2. Copy plugin files to Koha plugins directory:
   ```bash
   cp -r Koha/ /path/to/koha/plugins/
   ```

3. Enable plugins in Koha system preferences:
   - Set `UseKohaPlugins` to "Enable"
   - Restart web server and workers

4. Install the plugin through the Koha interface

## Configuration

### Initial Setup

1. Go to Home › Tools › Plugins
2. Find "Oracle Finance Integration" 
3. Click "Actions" › "Configure"

### Transport Configuration

Configure file transport for automated uploads:

1. **Transport Server**: Select configured file transport
2. **Schedule Days**: Choose days for automated processing
3. **Output Method**: 
   - "Local file" - Saves to plugin output directory
   - "Upload" - Uses configured transport server

### File Transport Setup

For automated uploads, configure a file transport in Koha:

1. Go to Administration › File transports
2. Create new transport with Oracle server details
3. Test connection before configuring plugin

## Verification

### Test Plugin Installation

1. Check plugin appears in Tools › Plugins
2. Verify configuration page loads
3. Test manual report generation:
   - Go to plugin tool interface
   - Select date range with known invoices
   - Generate test report

### Test Scheduled Processing

1. Configure plugin with appropriate schedule
2. Monitor plugin output directory or transport destination
3. Check for properly formatted files on scheduled days

## Troubleshooting

### Common Issues

**Plugin not appearing in list:**
- Verify `UseKohaPlugins` system preference is enabled
- Check file permissions in plugins directory
- Restart web server

**Configuration errors:**
- Verify required Perl modules are installed
- Check Koha logs for detailed error messages
- Ensure database connectivity

**Transport upload failures:**
- Test file transport configuration separately
- Verify network connectivity to Oracle server
- Check transport authentication credentials

**Empty or malformed output:**
- Verify RBKC suppliers exist in system
- Check fund code mappings in plugin
- Ensure invoices exist in date range

### Log Files

Check Koha logs for plugin-related errors:
- `/var/log/koha/instance/plack.log`
- `/var/log/koha/instance/plack-error.log`
- Web server error logs

### Support

- Create issue on [GitHub](https://github.com/openfifth/koha-plugin-rbkc-oracle/issues)
- Contact Open Fifth for RBKC-specific support
- Check [CONTRIBUTING.md](../CONTRIBUTING.md) for development setup