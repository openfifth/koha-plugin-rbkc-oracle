# Oracle Finance Integration

## Overview

This plugin exports Koha acquisition invoices to Oracle finance system format for RBKC (Royal Borough of Kensington and Chelsea). It generates CSV files with specific record types required by Oracle.

## File Format

### Record Types

The plugin generates three types of record lines in Oracle CSV format, all containing 24 fields:

#### Control Total (CT)

- **Purpose**: Summary record with total invoice count and amount
- **Position**: First line in file

| Field | Content         | Description                        |
| ----- | --------------- | ---------------------------------- |
| 1     | CT              | Record type identifier             |
| 2     | {invoice_count} | Total number of invoices           |
| 3     | {total_amount}  | Negative sum of all invoice totals |
| 4-24  | Empty           | Reserved fields                    |

#### Accounts Payable (AP)

- **Purpose**: One record per invoice with supplier details

| Field | Content              | Description                                                                            |
| ----- | -------------------- | -------------------------------------------------------------------------------------- |
| 1     | AP                   | Record type identifier                                                                 |
| 2     | {supplier_number}    | Supplier account number                                                                |
| 3     | {invoice_number}     | Invoice number                                                                         |
| 4     | {close_date}         | Invoice close date (YYYYMMDD)                                                          |
| 5     | {total_amount}       | Negative invoice total in pence                                                        |
| 6     | Empty                | Reserved field                                                                         |
| 7     | {invoice_number}     | Invoice reference (currently Koha invoicenumber, may refer to PO Number in the future) |
| 8-12  | Empty                | Reserved fields                                                                        |
| 13    | {currency_code}      | Currency code (e.g. GBP)                                                               |
| 14-23 | Empty                | Reserved fields                                                                        |
| 24    | {supplier_site_name} | Supplier site name                                                                     |

#### General Ledger (GL)

- **Purpose**: One record per order line quantity unit

| Field | Content            | Description                                                                            |
| ----- | ------------------ | -------------------------------------------------------------------------------------- |
| 1     | GL                 | Record type identifier                                                                 |
| 2     | {supplier_account} | Mapped supplier account from fund                                                      |
| 3     | {invoice_number}   | Invoice reference (currently Koha invoicenumber, may refer to PO Number in the future) |
| 4     | {unit_price}       | Unit price in pence                                                                    |
| 5     | Empty              | Reserved field                                                                         |
| 6     | {tax_code}         | Tax code (P1/P2/P3)                                                                    |
| 7-8   | Empty              | Reserved fields                                                                        |
| 9     | {analysis}         | Analysis code from fund mapping                                                        |
| 10    | Empty              | Reserved field                                                                         |
| 11    | {costcenter}       | Cost center from fund mapping                                                          |
| 12    | {invoice_number}   | Invoice number                                                                         |
| 13-24 | Empty              | Reserved fields                                                                        |

### Example Output

```csv
CT,2,-5000,,,,,,,,,,,,,,,,,,,,,
AP,12345,INV001,20241201,-2500,,INV001,,,,,GBP,,,,,,,,,,,RBKC_SITE
GL,4539,INV001,2000,,P1,,,,analysis,,E26315,INV001,,,,,,,,,,,
GL,4539,INV001,500,,P1,,,,analysis,,E26315,INV001,,,,,,,,,,,
AP,12346,INV002,20241201,-2500,,INV002,,,,,GBP,,,,,,,,,,,RBKC_SITE
GL,4539,INV002,2500,,P1,,,,analysis,,E26315,INV002,,,,,,,,,,,
```

## Data Mapping

### Fund Code Mappings

The plugin maps Koha fund codes to Oracle cost centers and supplier numbers:

#### Cost Centers

- Most funds → `E26315` (default)
- `KARC` → `E26311`
- `KERE` → `E26341`
- `KHLS` → `E26330`

#### Supplier Numbers

- Most funds → `4539` (default)
- `KERE` → `5190`
- `KPER` → `4625`

### Tax Code Mapping

Based on `tax_rate_on_receiving`:

- 20% → `P1`
- 5% → `P2`
- 0% → `P3`
- Other → Empty

## Business Logic

### Invoice Selection

- Only invoices from suppliers with names starting with "RBKC"
- Filtered by `closedate` within specified date range
- Includes associated order lines with budget information

### Quantity Handling

- Each order line quantity generates separate GL records
- If quantity is 5, creates 5 individual GL lines
- Each GL line uses unit price, not total price
- Invoice total correctly accounts for quantity × unit price

### Amount Calculations

- **Unit Prices**: Converted to pence (× 100) and rounded
- **Invoice Totals**: Sum of (unit price × quantity) for all lines
- **Tax Amounts**: Sum of tax values from all order lines
- **Control Total**: Negative sum of all invoice totals

## Scheduling

### Automated Processing

The plugin supports scheduled nightly processing:

1. **Configuration**: Select days of week for processing
2. **Date Range**: Calculates date range from last selected day to today
3. **Empty Check**: Returns early if no invoices found (cron mode)
4. **Output**: Saves to local file or uploads via transport

### Manual Processing

- Interactive date range selection
- HTML or text/CSV output options
- Download as attachment or view in browser

## File Naming

Generated files use format: `KC_LB02_YYYYMMDDHHMMSS.txt`

Example: `KC_LB02_20241201143052.txt`

## Integration Points

### Koha Dependencies

- **Acquisition System**: Invoices, orders, budgets
- **Suppliers**: Account numbers, names, contact info
- **File Transports**: For automated upload
- **Plugin Framework**: Configuration storage

### Oracle Dependencies

- **File Format**: CSV with specific field positions
- **Naming Convention**: KC_LB02 prefix required
- **Field Mappings**: Cost centers and supplier numbers
- **Business Rules**: Tax codes and amount formats

## Error Handling

### Validation

- **Missing Data**: Uses defaults (quantity = 1, unmapped funds)
- **Empty Results**: Graceful exit in cron mode
- **Transport Errors**: Logged but processing continues
- **File Errors**: Exception handling with cleanup

### Monitoring

- **Cron Jobs**: Silent success, logged failures
- **Manual Reports**: User feedback for errors
- **Version Sync**: Tests ensure consistency

## Customization

### Adding Fund Codes

1. Update `_map_fund_to_costcenter()` method
2. Update `_map_fund_to_suppliernumber()` method
3. Add test cases for new mappings
4. Document business justification

### Modifying File Format

1. Understand Oracle system requirements
2. Update record generation logic
3. Test with Oracle import process
4. Coordinate with RBKC finance team

### Transport Configuration

1. Set up file transport in Koha administration
2. Test connectivity and authentication
3. Configure plugin to use transport
4. Monitor automated uploads

## Troubleshooting

### Common Issues

**No output generated:**

- Check supplier names start with "RBKC"
- Verify invoices exist in date range
- Confirm invoices have closed status

**Incorrect amounts:**

- Verify quantity handling in order lines
- Check tax calculations on receiving
- Confirm currency and rounding logic

**Upload failures:**

- Test file transport configuration
- Check network connectivity
- Verify authentication credentials

**Mapping errors:**

- Review fund code mappings
- Check for unmapped funds in output
- Validate Oracle cost center codes
