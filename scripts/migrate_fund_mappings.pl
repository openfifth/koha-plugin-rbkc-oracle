#!/usr/bin/perl

# Migrate hardcoded RBKC fund mappings into plugin configuration storage.
#
# Run once after upgrading to the version that introduced UI-driven fund
# mappings.  Safe to run multiple times — it will not overwrite existing
# configuration unless --force is passed.
#
# Usage:
#   perl scripts/migrate_fund_mappings.pl
#   perl scripts/migrate_fund_mappings.pl --force   # overwrite existing

use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Mojo::JSON   qw(encode_json decode_json);

# Koha environment
use C4::Context;

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

my $PLUGIN_CLASS = 'Koha::Plugin::Com::OpenFifth::Oracle';
my $DATA_KEY     = 'fund_field_mappings';

my %MAPPINGS = (
    KAFI   => { costcenter => 'E26315', supplier_account => '4539' },
    KANF   => { costcenter => 'E26315', supplier_account => '4539' },
    KARC   => { costcenter => 'E26311', supplier_account => '4539' },
    KBAS   => { costcenter => 'E26315', supplier_account => '4539' },
    KCFI   => { costcenter => 'E26315', supplier_account => '4539' },
    KCHG   => { costcenter => 'E26315', supplier_account => '4539' },
    KCNF   => { costcenter => 'E26315', supplier_account => '4539' },
    KCOM   => { costcenter => 'E26315', supplier_account => '4539' },
    KEBE   => { costcenter => 'E26315', supplier_account => '4539' },
    KELE   => { costcenter => 'E26315', supplier_account => '4539' },
    KERE   => { costcenter => 'E26341', supplier_account => '5190' },
    KFSO   => { costcenter => 'E26315', supplier_account => '4539' },
    KHLS   => { costcenter => 'E26330', supplier_account => '4539' },
    KLPR   => { costcenter => 'E26315', supplier_account => '4539' },
    KNHC   => { costcenter => 'E26315', supplier_account => '4539' },
    KNSO   => { costcenter => 'E26315', supplier_account => '4539' },
    KPER   => { costcenter => 'E26315', supplier_account => '4625' },
    KRCHI  => { costcenter => 'E26315', supplier_account => '4539' },
    KREF   => { costcenter => 'E26315', supplier_account => '4539' },
    KREFSO => { costcenter => 'E26315', supplier_account => '4539' },
    KREP   => { costcenter => 'E26315', supplier_account => '4539' },
    KREQ   => { costcenter => 'E26315', supplier_account => '4539' },
    KRFI   => { costcenter => 'E26315', supplier_account => '4539' },
    KRNF   => { costcenter => 'E26315', supplier_account => '4539' },
    KSPO   => { costcenter => 'E26315', supplier_account => '4539' },
    KSSS   => { costcenter => 'E26315', supplier_account => '4539' },
    KVAT   => { costcenter => 'E26315', supplier_account => '4539' },
    KYAD   => { costcenter => 'E26315', supplier_account => '4539' },
);

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

my $force = 0;
GetOptions( 'force' => \$force ) or die "Usage: $0 [--force]\n";

my $dbh = C4::Context->dbh;

# Check for existing configuration
my ($existing) = $dbh->selectrow_array(
    'SELECT plugin_value FROM plugin_data WHERE plugin_class = ? AND plugin_key = ?',
    undef, $PLUGIN_CLASS, $DATA_KEY
);

my $already_set = $existing && $existing ne '{}';

if ( $already_set && !$force ) {
    my $current = eval { decode_json($existing) } || {};
    my $count = scalar keys %$current;
    print "Fund mappings already configured ($count funds stored).\n";
    print "Run with --force to overwrite.\n";
    exit 0;
}

if ( $already_set && $force ) {
    print "Overwriting existing fund mappings (--force specified).\n";
}

# Write mappings
my $json = encode_json( \%MAPPINGS );
$dbh->do(
    'REPLACE INTO plugin_data (plugin_class, plugin_key, plugin_value) VALUES (?, ?, ?)',
    undef, $PLUGIN_CLASS, $DATA_KEY, $json
);

my $count = scalar keys %MAPPINGS;
print "Done. Migrated $count fund mappings into plugin configuration.\n";
print "You can now view and edit them via: Plugins > RBKC Oracle > Configure.\n";
