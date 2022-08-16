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

* https://progenetix.org/cgi/pgxMaps/cgi/simpleMap.cgi?file=https://raw.githubusercontent.com/progenetix/pgxMaps/main/rsrc/locationtest.txt&-map_bubble_stroke_weight=2&-map_marker_scale=10

=cut

use strict;
use LWP::UserAgent ();
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;

BEGIN { unshift @INC, '../lib' };

use readFiles;
use setVars;
use webStats;
use plotGeomaps;

# print "Content-type: text/plain\n\n";

################################################################################
# parameter defaults & modifications ###########################################
################################################################################

my %args;

%args = pgInitializeCGI(%args);

# print Dumper(%args);

################################################################################

my ($header, $table) = lib::readFiles::read_webfile_to_split_array( $args{pgV}->{file} );
my @markers;

shift @$table;

foreach (@$table) {
	my ($title, $lat, $lon, $size, $type) = @$_;

	if ($lat !~ /^\-?\d+?(?:\.\d+?)?$/) { next }
	if ($lon !~ /^\-?\d+?(?:\.\d+?)?$/) { next }
	if ($size !~ /^\d+?(?:\.\d+?)?$/) { $size = 1 }

	# there are right now 2 marker types supported
	# * circle, scaled through $size
	# * marker
	# if not given, falls back to the processing standard (circle if more than 1)
	if (! grep{ $type eq $_ } qw(circle marker)) {
		$type = "" }

	push( @markers, [ $title, $lat, $lon, $size, $type ] );
}

if (@markers < 1) {
	push(
		@markers,
	 	[
			'SimpleMap script CC BY 4.0 <a href="http://info.baudisgroup.org/group/Michael-Baudis/">Michael Baudis</a>.<br/>For more information see our websites...',
			47.398,
			8.549,
			5000,
			'marker'
		]
	);
}

################################################################################

$args{'-plottype'}  =   'map';
my $pgx = new lib::plotGeomaps(\%args);
$pgx->{geomarkers} = \@markers;
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
