---

Analysis: Differences Between the Three Plugins

Overview

┌──────────────────┬───────────────────────────┬──────────────────────────────┬──────────────────────────────────┐
│ │ wcc-sap │ rbkc-oracle │ wscc-oracle │
├──────────────────┼───────────────────────────┼──────────────────────────────┼──────────────────────────────────┤
│ Finance system │ SAP │ Oracle │ Oracle │
├──────────────────┼───────────────────────────┼──────────────────────────────┼──────────────────────────────────┤
│ Report format │ CT/AP/GL, comma-delimited │ CT/AP/GL, comma-delimited │ Pipe-delimited with header │
├──────────────────┼───────────────────────────┼──────────────────────────────┼──────────────────────────────────┤
│ Report types │ Invoices only │ Invoices only │ Invoices + Income │
├──────────────────┼───────────────────────────┼──────────────────────────────┼──────────────────────────────────┤
│ Upload mechanism │ CGI sftp_upload │ REST API (inline api_routes) │ REST API (external openapi.json) │
├──────────────────┼───────────────────────────┼──────────────────────────────┼──────────────────────────────────┤
│ Fund mapping │ Hardcoded hash │ Hardcoded hash │ Dynamic UI-configurable │
├──────────────────┼───────────────────────────┼──────────────────────────────┼──────────────────────────────────┤
│ Vendor mapping │ N/A │ N/A │ Dynamic UI-configurable │
└──────────────────┴───────────────────────────┴──────────────────────────────┴──────────────────────────────────┘

wscc-oracle is architecturally much more advanced and mostly diverged intentionally. The actionable sync opportunities are
between wcc-sap and rbkc-oracle.

---

🐛 Bug: Cronjob date boundary — Fixed in wscc, missing from rbkc

wscc-oracle adds .add( days => 1 ) to start_date in cronjob_nightly, preventing invoices on the previous run's boundary date
from appearing in two consecutive runs.

rbkc-oracle Oracle.pm:112:
my $start_date =
$now->clone->subtract( days => ( $today - $previous_day ) % 7 );
wscc-oracle fix:
my $start_date =
$now->clone->subtract( days => ( $today - $previous_day ) % 7 )
->add( days => 1 );
wcc-sap has the same issue at SAP.pm:112.

---

🐛 Bug: Stale body ID in wscc templates — copy-paste artifact

Both wscc-oracle/report-step1.tt:16 and wscc-oracle/report-step2-html.tt:40 have:

  <body id="plugins_rbkc_oracle" class="plugins">
  Should be plugins_wscc_oracle.

---

🔧 Improvement: UploadController error handling — wscc has, rbkc missing

rbkc's UploadController.pm is missing:

1. \_extract_transport_error helper — detailed SFTP error info (operation, path, status_code, error_raw)
2. Proper HTTP status codes — rbkc uses 400 for everything; wscc uses 503 (no transport), 502 (SFTP failure), 500 (server
   error)
3. Connection check — wscc checks connect return value; rbkc just calls it blindly
4. Configurable upload directory — wscc reads upload_dir_income/upload_dir_invoices config

wscc's UploadController is essentially a superset of rbkc's.

---

🔧 Improvement: EDI_EXCL parsing in adjustments — rbkc has, wcc-sap missing

rbkc-oracle/Oracle.pm:504 parses raw EDI tax-exclusive amounts stored in the adjustment note:
if ( $note =~ /EDI_EXCL:\s\*([\d.]+)/ ) { # Use exact EDI tax-exclusive amount (from MOA+8)
$adjustment_amount_excl = $1;
}
wcc-sap only uses the fallback back-calculation path. If WCC's EDI imports store EDI_EXCL: in adjustment notes, wcc-sap would
produce less accurate values.

---

🔧 Improvement: rbkc report-step2-html.tt — doesn't send type in AJAX call

rbkc report-step2-html.tt:126 builds params without type:
var params = {
from: button.data('from'),
to: button.data('to')
};
While rbkc currently only has one report type so it doesn't matter functionally, and rbkc's UploadController doesn't require
it. This is consistent as-is, but the template also lacks error_detail display logic that wscc has.

---

Intentional differences (not bugs)

These are legitimately different between plugins and should not be synced:

- wcc-sap uses CGI-based sftp_upload rather than REST API — SAP-specific design
- wscc-oracle has income reports, dynamic UI-configurable fund/vendor mappings — WSCC-specific
- wcc-sap AP total = GL_sum + tax_sum (SAP format); rbkc uses Oracle's round(GL_total × 1.tax_rate) formula
- wscc-oracle is pipe-delimited with header row, completely different format

---

Recommended sync actions

For rbkc-oracle:

1. Fix the cronjob date boundary bug (add .add( days => 1 ))
2. Upgrade UploadController.pm with \_extract_transport_error, proper HTTP codes, connection check
3. Fix the copy-paste body IDs in wscc templates (if you own that repo)

For wcc-sap:

1. Fix the cronjob date boundary bug (add .add( days => 1 ))
2. Consider EDI_EXCL note parsing if WCC uses EDI imports that store that value

Want me to apply any of these fixes now?
