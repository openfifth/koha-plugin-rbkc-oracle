#!/usr/bin/perl

use Modern::Perl;
use Test::More;
use Test::Exception;
use JSON::MaybeXS;
use Path::Tiny;

BEGIN {
    plan tests => 5;
    use_ok('Koha::Plugin::Com::OpenFifth::Oracle') || print "Bail out!\n";
}

diag("Testing Koha::Plugin::Com::OpenFifth::Oracle");

# Test plugin instantiation
my $plugin;
lives_ok { $plugin = Koha::Plugin::Com::OpenFifth::Oracle->new() } 'Plugin instantiation succeeds';

# Test that the plugin has the required methods
can_ok($plugin, qw(configure cronjob_nightly report _generate_report _generate_filename));

# Test version synchronization between package.json and plugin
my $package_json_path = path(__FILE__)->parent->parent->child('package.json');
SKIP: {
    skip "package.json not found", 2 unless $package_json_path->exists;
    
    my $package_data = decode_json($package_json_path->slurp);
    my $package_version = $package_data->{version};
    
    ok($package_version, 'package.json has version');
    
    # Get plugin version from metadata
    my $plugin_version = $plugin->{metadata}->{version} || $Koha::Plugin::Com::OpenFifth::Oracle::VERSION;
    
    is($plugin_version, $package_version, 'Plugin version matches package.json version');
}

done_testing();