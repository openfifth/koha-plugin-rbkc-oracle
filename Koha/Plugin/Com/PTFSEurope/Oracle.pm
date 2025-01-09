package Koha::Plugin::Com::PTFSEurope::Oracle;

use Modern::Perl;

use base            qw{ Koha::Plugins::Base };
use Koha::DateUtils qw(dt_from_string);
use Koha::Number::Price;

use Mojo::JSON qw{ decode_json };

our $VERSION  = '0.0.8';
our $metadata = {
    name => 'Oracle Finance Integration',

    author          => 'PTFS Europe',
    date_authored   => '2024-11-15',
    date_updated    => '2024-11-15',
    minimum_version => '23.11.00.000',
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

    my $startdate = $cgi->param('startdate') ? dt_from_string($cgi->param('startdate')) : undef;
    my $enddate   = $cgi->param('enddate') ? dt_from_string($cgi->param('enddate')) : undef;

    my $template = $self->get_template( { file => 'report-step1.tt' } );
    $template->param(
        startdate => $startdate,
        enddate   => $enddate,
    );

    $self->output_html( $template->output() );
}

sub report_step2 {
    my ( $self, $args ) = @_;

    my $cgi = $self->{'cgi'};
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

    my $results = $self->_generate_report($startdate, $enddate);

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
    my ( $self, $startdate, $enddate ) = @_;

    my $dbh   = C4::Context->dbh;
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
        { prefetch => [ 'booksellerid', 'aqorders' ] } );

    my $results       = "";
    my $invoice_count = 0;
    my $overall_total = 0;
    while ( my $invoice = $invoices->next ) {
        $invoice_count++;
        my $lines  = "";
        my $orders = $invoice->_result->aqorders;

        # Collect 'General Ledger lines'
        my $invoice_total = 0;
        my $tax_amount = 0;
        while ( my $line = $orders->next ) {
            my $unitprice = Koha::Number::Price->new( $line->unitprice )->round * 100;
            $invoice_total = $invoice_total + $unitprice;
            my $tax_value_on_receiving = Koha::Number::Price->new( $line->tax_value_on_receiving )->round * 100;
            $tax_amount = $tax_amount + $tax_value_on_receiving;
            $lines .= "GL" . ","
              . $invoice->_result->booksellerid->address1 . ","
              . $invoice->invoicenumber . ","
              . $unitprice . ","
              . ","
              . $line->tax_rate_on_receiving . ","
              . ","
              . ","
              . ","
              . "Statistical" . ","
              . ","
              . $invoice->_result->booksellerid->type . ","
              . $invoice->invoicenumber . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . "," 
              . "\n";
        }

        # Add 'Accounts Payable line'
        $invoice_total = $invoice_total * -1;
        $overall_total = $overall_total + $invoice_total;
        $results .= "AP" . ","
          . $invoice->_result->booksellerid->accountnumber . ","
          . $invoice->invoicenumber . ","
          . ( $invoice->closeddate =~ s/-//gr ) . ","
          . $invoice_total . ","
          . $tax_amount . ","
          . $invoice->invoicenumber . ","
          . ( $invoice->shipmentdate =~ s/-//gr ) . ","
          . ","
          . ","
          . ","
          . ","
          . $invoice->_result->booksellerid->invoiceprice->currency . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . $invoice->_result->booksellerid->fax
          . "\n";
        $results .= $lines;
    }

    # Add 'Control Total line'
    $overall_total = $overall_total * -1;
    $results = "CT" . ","
      . $invoice_count . ","
      . $overall_total . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . "\n"
      . $results;

      return $results;
}

sub _generate_filename {
    my ($self, $args) = @_;

    my $filename = "KC_LB01_" . dt_from_string()->strftime('%Y%m%d%H%M%S');
    my $extension = ".txt";

    return $filename . $extension;
}

1;
