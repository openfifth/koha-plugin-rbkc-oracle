package Koha::Plugin::Com::PTFSEurope::Oracle;

use Modern::Perl;

use base qw{ Koha::Plugins::Base };
use Koha::DateUtils qw(dt_from_string);

use Mojo::JSON qw{ decode_json };

our $VERSION  = '0.0.1';
our $metadata = {
    name            => 'Oracle Finance Integration',

    author          => 'PTFS Europe',
    date_authored   => '2024-11-15',
    date_updated    => '2024-11-15',
    minimum_version => '23.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'A plugin to manage finance integration for RBKC with Oracle',
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'}            = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self     = $class->SUPER::new( $args );
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

    my $template = $self->get_template({ file => 'report-step1.tt' });
    $self->output_html( $template->output() );
}

sub report_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $dbh = C4::Context->dbh;
    my $output = $cgi->param('output');
#    my $fromDay   = $cgi->param('fromDay');
#    my $fromMonth = $cgi->param('fromMonth');
#    my $fromYear  = $cgi->param('fromYear');
#
#    my $toDay   = $cgi->param('toDay');
#    my $toMonth = $cgi->param('toMonth');
#    my $toYear  = $cgi->param('toYear');
#
#    my ( $fromDate, $toDate );
#    if ( $fromDay && $fromMonth && $fromYear && $toDay && $toMonth && $toYear )
#    {
#        $fromDate = "$fromYear-$fromMonth-$fromDay";
#        $toDate   = "$toYear-$toMonth-$toDay";
#    }

    my $invoices = Koha::Acquisition::Invoices->search({},{ prefetch => [ 'booksellerid', 'aqorders' ]});

    my $results = "";
    while ( my $invoice = $invoices->next ) {
        my $lines = "";
        for my $line ( $invoice->aqorders ) {
            $lines .= "GL,".$invoice->invoicenumber.",".$line->ordernumber.",".$line->unitprice.",".$invoice->aqbooksellerid->accountnumber.",".$line->tax_rate_bak.",".$line->budgetid->budgetname."\n";
        }
        $results .= "AP,".$invoice->invoicenumber.",".$invoice->billingdate.",KC,"."TOTAL".","."TAX".",".$invoice->aqbooksellerid->fax.",".$invoice->shipmentdate.",".$invoice->booksellerid."\n";
        $results .= $lines;
    }

    my $filename;
    if ( $output eq "txt" ) {
        print $cgi->header( -attachment => 'oracle.txt' );
        $filename = 'report-step2-txt.tt';
    }
    else {
        print $cgi->header();
        $filename = 'report-step2-html.tt';
    }

    my $template = $self->get_template({ file => $filename });

    $template->param(
        date_ran     => dt_from_string(),
        results      => $results,
    );

    print $template->output();
}

1;
