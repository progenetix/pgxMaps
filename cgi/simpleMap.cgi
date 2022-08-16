#!/usr/bin/perl -w

################################################################################
#                                                                              #
# Progenetix & arrayMap site scripts                                           #
#                                                                              #
# molecular cytogenetics, Comparative Genomic Hybridization, genomic arrays    #
# data analysis & visualization                                                #
#                                                                              #
# © 2000-2022 Michael Baudis: michael@baud.is                                  #
#                                                                              #
################################################################################

=pod

Documentation:

Example:

* https://progenetix.org/cgi/pgxMaps/cgi/simpleMap.cgi?file=https://raw.githubusercontent.com/progenetix/pgxMaps/main/rsrc/locationtest.tsv&-map_bubble_stroke_weight=2&-map_marker_scale=10

=cut

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(param multi_param);
use Data::Dumper;

BEGIN { unshift @INC, '../lib' };

use readFiles;
use webStats;
use plotGeomaps;

# print "Content-type: text/plain\n\n";

################################################################################
# parameter defaults & modifications ###########################################
################################################################################

my %args;

$args{pgV} = {};
# TODO: This needs a clean processing of allowed parameters!
foreach my $key (param()) {
	$args{pgV}->{$key} = param($key);
}
$args{google_params} = pgSendGoogleTracking();

# print Dumper(%args);

################################################################################

my ($header, $table) = lib::readFiles::read_webfile_to_split_array( $args{pgV}->{file} );
my @markers;

# removing header line
shift @$table;

 
my $markers = {};

foreach (@$table) {

	my ($group, $lat, $lon, $size, $label, $link, $markerType) = @$_;

	if ($lat !~ /^\-?\d+?(?:\.\d+?)?$/) { next }
	if ($lon !~ /^\-?\d+?(?:\.\d+?)?$/) { next }
	if ($size !~ /^\d+?(?:\.\d+?)?$/) { $size = 1 }

	my $m_k = $group."::".$lat."::".$lon;

	# there are right now 2 marker types supported
	# * circle, scaled through $size
	# * marker
	# if not given, falls back to the processing standard (circle if more than 1)
	if (! grep{ $markerType eq $_ } qw(circle marker)) {
		$markerType = "" }

	$markers->{$m_k}->{group} = $group;
	$markers->{$m_k}->{lat} = $lat;
	$markers->{$m_k}->{lon} = $lon;
	$markers->{$m_k}->{type} = $markerType;
	$markers->{$m_k}->{size} += $size;

	if ($link =~ /http/) {
		$label = '<a href="'.$link.'">'.$label.'</a>' }

	push(@{$markers->{$m_k}->{items}}, $label);
    # print Dumper($markers->{$m_k});

}

if (scalar keys %{ $markers } < 1) {
	$markers = {
		group => "Test",
		lat => 47.398,
		lon => 8.549,
		size => 5000,
		type => "marker"
	}
}

################################################################################

$args{'-plottype'} = 'map';
my $pgx = new lib::plotGeomaps(\%args);
$pgx->{geomarkers} = $markers;
$pgx->pgx_get_web_geomap();

print <<END;
Content-type: text/html
User-Agent: Mozilla/5.0



<html>
$pgx->{map}
</html>
END

exit;



1;
