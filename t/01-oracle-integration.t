#!/usr/bin/perl

use Modern::Perl;
use Test::More;
use Test::Exception;

BEGIN {
    plan tests => 8;
    use_ok('Koha::Plugin::Com::OpenFifth::Oracle') || print "Bail out!\n";
}

my $plugin = Koha::Plugin::Com::OpenFifth::Oracle->new();

# Test fund mapping methods
subtest 'Fund to cost center mapping' => sub {
    plan tests => 4;
    
    is($plugin->_map_fund_to_costcenter('KAFI'), 'E26315', 'KAFI maps to correct cost center');
    is($plugin->_map_fund_to_costcenter('KERE'), 'E26341', 'KERE maps to correct cost center'); 
    is($plugin->_map_fund_to_costcenter('KHLS'), 'E26330', 'KHLS maps to correct cost center');
    is($plugin->_map_fund_to_costcenter('INVALID'), 'UNMAPPED', 'Invalid fund maps to UNMAPPED');
};

subtest 'Fund to supplier number mapping' => sub {
    plan tests => 4;
    
    is($plugin->_map_fund_to_suppliernumber('KAFI'), 4539, 'KAFI maps to correct supplier number');
    is($plugin->_map_fund_to_suppliernumber('KERE'), 5190, 'KERE maps to correct supplier number');
    is($plugin->_map_fund_to_suppliernumber('KPER'), 4625, 'KPER maps to correct supplier number');  
    is($plugin->_map_fund_to_suppliernumber('INVALID'), 'UNMAPPED', 'Invalid fund maps to UNMAPPED');
};

# Test filename generation
subtest 'Filename generation' => sub {
    plan tests => 2;
    
    my $filename = $plugin->_generate_filename();
    like($filename, qr/^KC_LB02_\d{14}\.txt$/, 'Filename follows correct pattern');
    ok(length($filename) == 21, 'Filename has correct length');
};

# Test cron parameter handling
subtest '_generate_report with cron parameter' => sub {
    plan tests => 2;
    
    # Mock DateTime for consistent testing
    my $start_date = DateTime->new(year => 2024, month => 1, day => 1);
    my $end_date = DateTime->new(year => 2024, month => 1, day => 31);
    
    # Test that cron parameter is accepted
    lives_ok { 
        $plugin->_generate_report($start_date, $end_date, 'cron'); 
    } '_generate_report accepts cron parameter';
    
    lives_ok { 
        $plugin->_generate_report($start_date, $end_date); 
    } '_generate_report works without cron parameter';
};

# Test metadata structure
subtest 'Plugin metadata' => sub {
    plan tests => 6;
    
    my $metadata = $plugin->{metadata};
    
    ok($metadata->{name}, 'Plugin has name');
    ok($metadata->{author}, 'Plugin has author');
    ok($metadata->{version}, 'Plugin has version');
    ok($metadata->{description}, 'Plugin has description');
    ok($metadata->{date_authored}, 'Plugin has date_authored');
    ok($metadata->{minimum_version}, 'Plugin has minimum_version');
};

# Test required plugin methods exist
subtest 'Required plugin methods' => sub {
    plan tests => 6;
    
    can_ok($plugin, 'configure');
    can_ok($plugin, 'cronjob_nightly'); 
    can_ok($plugin, 'report');
    can_ok($plugin, '_generate_report');
    can_ok($plugin, '_generate_filename');
    can_ok($plugin, 'new');
};

# Test configuration parameter handling
subtest 'Configuration handling' => sub {
    plan tests => 2;
    
    # Test that plugin can store and retrieve data
    lives_ok {
        $plugin->store_data({ test_key => 'test_value' });
    } 'Can store configuration data';
    
    my $retrieved = $plugin->retrieve_data('test_key');
    is($retrieved, 'test_value', 'Can retrieve stored configuration data');
};

done_testing();