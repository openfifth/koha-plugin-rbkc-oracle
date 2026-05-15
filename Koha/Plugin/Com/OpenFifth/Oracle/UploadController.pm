package Koha::Plugin::Com::OpenFifth::Oracle::UploadController;

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';
use Koha::DateUtils qw( dt_from_string );
use Koha::File::Transports;
use File::Spec;

=head1 API

=head2 Class Methods

=head3 upload

Handle upload/save operations for Oracle reports

=cut

sub upload {
    my $c = shift->openapi->valid_input or return;

    # Get the plugin instance
    my $plugin_class = "Koha::Plugin::Com::OpenFifth::Oracle";
    my $plugin = $plugin_class->new();

    # Get parameters
    my $from = $c->validation->param('from');
    my $to = $c->validation->param('to');

    # Parse dates
    my $startdate = eval { dt_from_string($from) };
    my $enddate = eval { dt_from_string($to) };

    unless ($startdate && $enddate) {
        return $c->render(
            status => 400,
            openapi => {
                success => Mojo::JSON->false,
                message => "Invalid date parameters"
            }
        );
    }

    # TO is exclusive: the actual scanned window ends the day before the
    # user-selected TO date, mirroring the report UI labels ("Closed on
    # or after" / "Closed before") and the cron's day-granular window.
    my $effective_enddate = $enddate->clone->subtract( days => 1 );

    my $window_text = $plugin->_window_text( $startdate, $effective_enddate );
    my $prefix      = "[$window_text] (manual)";

    # Check output configuration
    my $output = $plugin->retrieve_data('output');

    if ($output eq 'upload') {
        # Get transport configuration
        my $transport = Koha::File::Transports->find( $plugin->retrieve_data('transport_server') );
        unless ($transport) {
            $plugin->_add_cron_run_log({
                status  => 'error',
                message => "$prefix No SFTP transport configured",
            });
            return $c->render(
                status => 400,
                openapi => {
                    success => Mojo::JSON->false,
                    message => "No SFTP transport configured"
                }
            );
        }

        # Generate report
        my $filename = $plugin->_generate_filename();
        my $report = $plugin->_generate_report( $startdate, $effective_enddate );

        unless ($report) {
            $plugin->_add_cron_run_log({
                status  => 'error',
                message => "$prefix Failed to generate report",
            });
            return $c->render(
                status => 400,
                openapi => {
                    success => Mojo::JSON->false,
                    message => "Failed to generate report"
                }
            );
        }

        my $invoices_found = scalar @{ $plugin->{_processed_invoices} || [] };

        # Upload to SFTP
        eval {
            $transport->connect;
            open my $fh, '<', \$report;
            my $upload_result = $transport->upload_file( $fh, $filename );
            close $fh;

            if ($upload_result) {
                $plugin->_mark_invoices_submitted( $plugin->{_processed_invoices}, $filename, 'manual' );
                $plugin->_add_cron_run_log({
                    status         => 'success',
                    invoices_found => $invoices_found,
                    filename       => $filename,
                    message        => "$prefix Uploaded $filename",
                });
                return $c->render(
                    status => 200,
                    openapi => {
                        success => Mojo::JSON->true,
                        message => "File uploaded successfully to SFTP server",
                        filename => $filename
                    }
                );
            } else {
                $plugin->_add_cron_run_log({
                    status         => 'error',
                    invoices_found => $invoices_found,
                    filename       => $filename,
                    message        => "$prefix Upload failed for $filename",
                });
                return $c->render(
                    status => 400,
                    openapi => {
                        success => Mojo::JSON->false,
                        message => "Failed to upload file to SFTP server"
                    }
                );
            }
        };

        if ($@) {
            $plugin->_add_cron_run_log({
                status         => 'error',
                invoices_found => $invoices_found,
                filename       => $filename,
                message        => "$prefix SFTP upload exception: $@",
            });
            return $c->render(
                status => 400,
                openapi => {
                    success => Mojo::JSON->false,
                    message => "SFTP upload error: $@"
                }
            );
        }
    } else {
        # Save to local file
        my $filename = $plugin->_generate_filename();
        my $report = $plugin->_generate_report( $startdate, $effective_enddate );

        unless ($report) {
            $plugin->_add_cron_run_log({
                status  => 'error',
                message => "$prefix Failed to generate report",
            });
            return $c->render(
                status => 400,
                openapi => {
                    success => Mojo::JSON->false,
                    message => "Failed to generate report"
                }
            );
        }

        my $invoices_found = scalar @{ $plugin->{_processed_invoices} || [] };
        my $file_path = File::Spec->catfile( $plugin->bundle_path, 'output', $filename );

        eval {
            open( my $fh, '>', $file_path ) or die "Unable to open $file_path: $!";
            print $fh $report;
            close($fh);

            $plugin->_mark_invoices_submitted( $plugin->{_processed_invoices}, $filename, 'manual' );
            $plugin->_add_cron_run_log({
                status         => 'success',
                invoices_found => $invoices_found,
                filename       => $filename,
                message        => "$prefix Wrote local file $file_path",
            });
            return $c->render(
                status => 200,
                openapi => {
                    success => Mojo::JSON->true,
                    message => "File saved successfully to server",
                    filename => $filename
                }
            );
        };

        if ($@) {
            $plugin->_add_cron_run_log({
                status         => 'error',
                invoices_found => $invoices_found,
                filename       => $filename,
                message        => "$prefix Error saving file $file_path: $@",
            });
            return $c->render(
                status => 400,
                openapi => {
                    success => Mojo::JSON->false,
                    message => "Error saving file: $@"
                }
            );
        }
    }
}

1;
