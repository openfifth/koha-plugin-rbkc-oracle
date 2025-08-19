package Koha::Plugin::Com::OpenFifth::Oracle;

use Modern::Perl;

use base            qw{ Koha::Plugins::Base };
use Koha::DateUtils qw(dt_from_string);
use Koha::File::Transports;
use Koha::Number::Price;

use File::Spec;
use List::Util qw(min max);
use Mojo::JSON qw{ decode_json };
use Text::CSV;

our $VERSION = '0.0.30';

our $metadata = {
    name => 'Oracle Finance Integration',

    author          => 'Open Fifth',
    date_authored   => '2024-11-15',
    date_updated    => '2025-08-19',
    minimum_version => '24.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     =>
      'A plugin to manage finance integration for RBKC with Oracle',
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);
    $self->{cgi} = CGI->new();

    return $self;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );

        ## Grab the values we already have for our settings, if any exist
        my $available_transports = Koha::File::Transports->search();
        my @days_of_week =
          qw(sunday monday tuesday wednesday thursday friday saturday);
        my $transport_days = {
            map  { $days_of_week[$_] => 1 }
            grep { defined $days_of_week[$_] }
              split( ',', $self->retrieve_data('transport_days') )
        };
        $template->param(
            transport_server     => $self->retrieve_data('transport_server'),
            transport_days       => $transport_days,
            output               => $self->retrieve_data('output'),
            available_transports => $available_transports
        );

        $self->output_html( $template->output() );
    }
    else {
        # Get selected days (returns an array from multiple checkboxes)
        my @selected_days = $cgi->multi_param('days');
        my $days_str      = join( ',', sort { $a <=> $b } @selected_days );
        $self->store_data(
            {
                transport_server => scalar $cgi->param('transport_server'),
                transport_days   => $days_str,
                output           => scalar $cgi->param('output')
            }
        );
        $self->go_home();
    }
}

sub cronjob_nightly {
    my ($self) = @_;

    my $transport_days = $self->retrieve_data('transport_days');
    return unless $transport_days;

    my @selected_days = sort { $a <=> $b } split( /,/, $transport_days );
    my %selected_days = map  { $_ => 1 } @selected_days;

    # Get current day of the week (0=Sunday, ..., 6=Saturday)
    my $today = dt_from_string()->day_of_week % 7;
    return unless $selected_days{$today};

    my $output = $self->retrieve_data('output');
    my $transport;
    if ( $output eq 'upload' ) {
        $transport = Koha::File::Transports->find(
            $self->retrieve_data('transport_server') );
        return unless $transport;
    }

    # Find start date (previous selected day) and end date (today)
    my $previous_day =
      max( grep { $_ < $today } @selected_days );   # Last selected before today
    $previous_day //=
      $selected_days[-1];    # Wrap around to last one from previous week

    # Calculate the start date (previous selected day) and end date (today)
    my $now = DateTime->now;
    my $start_date =
      $now->clone->subtract( days => ( $today - $previous_day ) % 7 );
    my $end_date = $now;

    my $report = $self->_generate_report( $start_date, $end_date, 1 );
    return if !$report;
    my $filename = $self->_generate_filename();

    if ( $output eq 'upload' ) {
        $transport->connect;
        open my $fh, '<', \$report;
        if ( $transport->upload_file( $fh, $filename ) ) {
            close $fh;
            return 1;
        }
        else {
            # Deal with transport errors?
            close $fh;
            return 0;
        }
    }
    else {
        my $file_path =
          File::Spec->catfile( $self->bundle_path, 'output', $filename );
        open( my $fh, '>', $file_path ) or die "Unable to open $file_path: $!";
        print $fh $report;
        close($fh);
        return 1;
    }
}

sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('output') ) {
        $self->report_step1();
    }
    else {
        $self->report_step2();
    }
}

sub report_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $startdate =
      $cgi->param('startdate')
      ? dt_from_string( $cgi->param('startdate') )
      : undef;
    my $enddate =
      $cgi->param('enddate') ? dt_from_string( $cgi->param('enddate') ) : undef;

    my $template = $self->get_template( { file => 'report-step1.tt' } );
    $template->param(
        startdate => $startdate,
        enddate   => $enddate,
    );

    $self->output_html( $template->output() );
}

sub report_step2 {
    my ( $self, $args ) = @_;

    my $cgi       = $self->{'cgi'};
    my $startdate = $cgi->param('from');
    my $enddate   = $cgi->param('to');
    my $output    = $cgi->param('output');

    if ($startdate) {
        $startdate =~ s/^\s+//;
        $startdate =~ s/\s+$//;
        $startdate = eval { dt_from_string($startdate) };
    }

    if ($enddate) {
        $enddate =~ s/^\s+//;
        $enddate =~ s/\s+$//;
        $enddate = eval { dt_from_string($enddate) };
    }

    my $results = $self->_generate_report( $startdate, $enddate );

    my $templatefile;
    if ( $output eq "txt" ) {
        my $filename = $self->_generate_filename;
        print $cgi->header( -attachment => "$filename" );
        $templatefile = 'report-step2-txt.tt';
    }
    else {
        print $cgi->header();
        $templatefile = 'report-step2-html.tt';
    }

    my $template = $self->get_template( { file => $templatefile } );

    $template->param(
        date_ran  => dt_from_string(),
        startdate => dt_from_string($startdate),
        enddate   => dt_from_string($enddate),
        results   => $results,
    );

    print $template->output();
}

sub _generate_report {
    my ( $self, $startdate, $enddate, $cron ) = @_;

    my $where = { 'booksellerid.name' => { 'LIKE' => 'RBKC%' } };

    my $dtf           = Koha::Database->new->schema->storage->datetime_parser;
    my $startdate_iso = $dtf->format_date($startdate);
    my $enddate_iso   = $dtf->format_date($enddate);
    if ( $startdate_iso && $enddate_iso ) {
        $where->{'me.closedate'} =
          [ -and => { '>=', $startdate_iso }, { '<=', $enddate_iso } ];
    }
    elsif ($startdate_iso) {
        $where->{'me.closedate'} = { '>=', $startdate_iso };
    }
    elsif ($enddate_iso) {
        $where->{'me.closedate'} = { '<=', $enddate_iso };
    }

    my $invoices = Koha::Acquisition::Invoices->search( $where,
        { prefetch => [ 'booksellerid', 'aqorders', 'aqinvoice_adjustments' ] } );

    return 0 if $invoices->count == 0 && $cron;

    # Initialize Text::CSV for proper CSV formatting
    my $csv = Text::CSV->new({
        binary => 1,
        eol => "\015\012",
        sep_char => ",",
        quote_char => '"',
        always_quote => 0
    });

    my $results = "";
    open my $fh, '>', \$results or die "Could not open scalar ref: $!";

    my $invoice_count = 0;
    my $overall_total = 0;
    my @all_rows = ();  # Store all rows to add CT row at the beginning
    while ( my $invoice = $invoices->next ) {
        $invoice_count++;
        my $lines  = "";
        my $orders = $invoice->_result->aqorders;

        # Collect and categorize adjustments first
        my $adjustments = $invoice->_result->aqinvoice_adjustments;
        my $total_adjustments = 0;
        my @general_adjustments = ();    # Adjustments without order references
        my %order_adjustments = ();      # Adjustments with order numbers, keyed by ordernumber
        
        while ( my $adjustment = $adjustments->next ) {
            my $adjustment_amount = Koha::Number::Price->new( $adjustment->adjustment )->round * 100;
            $total_adjustments += $adjustment_amount;
            
            # Determine which order this adjustment applies to from the note field
            my $adjustment_note = $adjustment->note || '';
            my $adjustment_ordernumber = '';
            if ($adjustment_note =~ /Order #(\d+)/) {
                $adjustment_ordernumber = $1;
                # Store adjustment for later insertion after the corresponding order
                push @{$order_adjustments{$adjustment_ordernumber}}, $adjustment;
            } else {
                # Store general adjustment for insertion at the top
                push @general_adjustments, $adjustment;
            }
        }

        # Helper function to generate adjustment GL row
        my $generate_adjustment_row = sub {
            my ($adjustment) = @_;
            my $adjustment_amount = Koha::Number::Price->new( $adjustment->adjustment )->round * 100;
            
            # Use the adjustment's budget if available, otherwise fallback to first order's budget
            my $adj_budget_code;
            if ($adjustment->budget_id) {
                my $adj_fund = Koha::Acquisition::Funds->find($adjustment->budget_id);
                $adj_budget_code = $adj_fund ? $adj_fund->budget_code : '';
            } elsif ($orders->count > 0) {
                $orders->reset;  # Reset iterator to access first element
                $adj_budget_code = $orders->first->budget->budget_code;
            } else {
                $adj_budget_code = '';  # No budget info available
            }

            my $supplier_account = $self->_map_fund_to_supplier_account($adj_budget_code);
            my $costcenter = $self->_map_fund_to_costcenter($adj_budget_code);
           
            return [
                "GL",                                                    # 1
                $supplier_account,                                       # 2
                $invoice->invoicenumber,                                # 3
                $adjustment_amount,                                      # 4
                "",                                                     # 5
                "P3",                                                   # 6 Fixed tax code for service charges
                "", "",                                                 # 7-8
                $self->_map_fund_to_analysis($adj_budget_code),         # 9
                "",                                                     # 10
                $costcenter,                                            # 11
                $invoice->invoicenumber,                                # 12
                "", "", "", "", "", "", "", "", "", "", "", ""         # 13-24
            ];
        };

        # Add general adjustments (no line ID) at the top
        for my $adjustment (@general_adjustments) {
            push @all_rows, $generate_adjustment_row->($adjustment);
        }

        # Collect 'General Ledger lines' for orders, interleaving order-specific adjustments
        my $invoice_total = 0;
        my $tax_amount = 0;
        while ( my $line = $orders->next ) {
            my $supplier_account = $self->_map_fund_to_supplier_account($line->budget->budget_code);
            my $costcenter = $self->_map_fund_to_costcenter($line->budget->budget_code);

            my $unitprice = Koha::Number::Price->new( $line->unitprice_tax_included )->round * 100;
            my $quantity = $line->quantity || 1;
            $invoice_total = $invoice_total + ($unitprice * $quantity);
            my $tax_value_on_receiving = Koha::Number::Price->new( $line->tax_value_on_receiving )->round * 100;
            $tax_amount = $tax_amount + $tax_value_on_receiving;
            my $tax_rate_on_receiving = $line->tax_rate_on_receiving * 100;
            my $tax_code =
                $tax_rate_on_receiving == 20 ? 'P1'
              : $tax_rate_on_receiving == 5  ? 'P2'
              : $tax_rate_on_receiving == 0  ? 'P3'
              :                                '';

            # Generate one GL row per quantity unit
            for my $qty_unit (1..$quantity) {
                push @all_rows, [
                    "GL",                                               # 1
                    $supplier_account,                                  # 2
                    $invoice->invoicenumber,                           # 3
                    $unitprice,                                        # 4
                    "",                                                # 5
                    $tax_code,                                         # 6
                    "", "",                                            # 7-8
                    $self->_map_fund_to_analysis($line->budget->budget_code), # 9
                    "",                                                # 10
                    $costcenter,                                       # 11
                    $invoice->invoicenumber,                           # 12
                    "", "", "", "", "", "", "", "", "", "", "", ""    # 13-24
                ];
            }

            # Add any adjustments that reference this order
            my $current_ordernumber = $line->ordernumber;
            if (exists $order_adjustments{$current_ordernumber}) {
                for my $adjustment (@{$order_adjustments{$current_ordernumber}}) {
                    push @all_rows, $generate_adjustment_row->($adjustment);
                }
                # Remove processed adjustments to avoid duplicates
                delete $order_adjustments{$current_ordernumber};
            }

        }

        # Add adjustments to invoice total
        $invoice_total += $total_adjustments;

        # Add 'Accounts Payable row'
        my $supplier_number    = $invoice->_result->booksellerid->accountnumber;
        my $supplier_site_name = $invoice->_result->booksellerid->fax;
        $invoice_total = $invoice_total * -1;
        $overall_total = $overall_total + $invoice_total;
        
        push @all_rows, [
            "AP",                                                   # 1
            $supplier_number,                                       # 2
            $invoice->invoicenumber,                               # 3
            ($invoice->closedate =~ s/-//gr),                      # 4
            $invoice_total,                                        # 5
            "",                                                    # 6
            $invoice->invoicenumber,                               # 7
            "", "", "", "", "",                                    # 8-12
            $invoice->_result->booksellerid->invoiceprice->currency, # 13
            "", "", "", "", "", "", "", "", "", "", "",           # 14-23
            $supplier_site_name                                    # 24
        ];
    }

    # Add 'Control Total row' at the beginning
    $overall_total = $overall_total * -1;
    my $ct_row = [
        "CT",                                                       # 1
        $invoice_count,                                             # 2
        $overall_total,                                             # 3
        "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" # 4-24
    ];
    
    # Print Control Total first, then all other rows
    $csv->print($fh, $ct_row);
    for my $row (@all_rows) {
        $csv->print($fh, $row);
    }
    
    close $fh;
    return $results;
}

sub _generate_filename {
    my ( $self, $args ) = @_;

    my $filename  = "KC_LB02_" . dt_from_string()->strftime('%Y%m%d%H%M%S');
    my $extension = ".txt";

    return $filename . $extension;
}

sub _map_fund_to_costcenter {
    my ( $self, $fund ) = @_;
    my $map = {
        KAFI   => "E26315",
        KANF   => "E26315",
        KARC   => "E26311",
        KBAS   => "E26315",
        KCFI   => "E26315",
        KCHG   => "E26315",
        KCNF   => "E26315",
        KCOM   => "E26315",
        KEBE   => "E26315",
        KELE   => "E26315",
        KERE   => "E26341",
        KFSO   => "E26315",
        KHLS   => "E26330",
        KLPR   => "E26315",
        KNHC   => "E26315",
        KNSO   => "E26315",
        KPER   => "E26315",
        KRCHI  => "E26315",
        KREF   => "E26315",
        KREFSO => "E26315",
        KREP   => "E26315",
        KREQ   => "E26315",
        KRFI   => "E26315",
        KRNF   => "E26315",
        KSPO   => "E26315",
        KSSS   => "E26315",
        KVAT   => "E26315",
        KYAD   => "E26315",
    };
    my $return = defined( $map->{$fund} ) ? $map->{$fund} : 'UNMAPPED';
    return $return;
}

sub _map_fund_to_supplier_account {
    my ( $self, $fund ) = @_;
    my $map = {
        KAFI   => 4539,
        KANF   => 4539,
        KARC   => 4539,
        KBAS   => 4539,
        KCFI   => 4539,
        KCHG   => 4539,
        KCNF   => 4539,
        KCOM   => 4539,
        KEBE   => 4539,
        KELE   => 4539,
        KERE   => 5190,
        KFSO   => 4539,
        KHLS   => 4539,
        KLPR   => 4539,
        KNHC   => 4539,
        KNSO   => 4539,
        KPER   => 4625,
        KRCHI  => 4539,
        KREF   => 4539,
        KREFSO => 4539,
        KREP   => 4539,
        KREQ   => 4539,
        KRFI   => 4539,
        KRNF   => 4539,
        KSPO   => 4539,
        KSSS   => 4539,
        KVAT   => 4539,
        KYAD   => 4539,
    };
    my $return = defined( $map->{$fund} ) ? $map->{$fund} : 'UNMAPPED';
    return $return;
}

sub _map_fund_to_analysis {
    my ( $self, $fund ) = @_;
    return 'analysis';
}

1;
