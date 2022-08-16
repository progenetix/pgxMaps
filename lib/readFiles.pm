package lib::readFiles;

use Data::Dumper;
use LWP::UserAgent ();

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	read_file_to_split_array
	read_webfile_to_split_array
);

################################################################################

sub _f2l {

	my $file = shift;
	open FILE, "$file" or die "No file $file $!";
	local $/;
	my $fContent = <FILE>;
	close FILE;
	return [ split(/\r\n?|\n/, $fContent) ];

}

################################################################################

sub _l2t {

	my $list = shift;
	my $header = [ ];
	my $table = [ ];
	foreach (@$list) {
		if (/^\#/) {
			push( @$header, $_) }
		else {
			push( @$table, [ split("\t", $_) ] ) }
	}
	return ($header, $table);

}

################################################################################

sub read_file_to_split_array {

	my $file = shift;

	if ($file =~ /\.(ods)|(xlsx?)$/i) {
		use	Spreadsheet::Read;
		use Spreadsheet::ReadSXC;
		my $book = ReadData($file);
		my $header = [ ];
		my $table = [ ];
		foreach my $currentRow (Spreadsheet::Read::rows($book->[1])) {
			if ($currentRow->[0] =~ /^\#/) {
				push( @$header, $currentRow) }
		else {
			push( @$table, $currentRow ) }
		}
		return ($header, $table);
	}
	
	return _l2t( _f2l( $file ) );

}

################################################################################

sub read_webfile_to_split_array {

	use LWP::UserAgent;
	use LWP::Simple;
	use	Spreadsheet::Read;
	use Spreadsheet::ReadSXC;

	my $web = shift;

	if ($web =~ /dropbox\.com/) {
	$web =~	s/(\?dl=\w)?$/?dl=1/ }

	$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

	my $ua = new LWP::UserAgent;
	$ua->agent("Mozilla/8.0");

	my $req = new HTTP::Request 'GET' => $web;
	$req->header('Accept' => 'text/plain');

	my $res = $ua->request($req);
	my @content;

	if ($res =~ /\.(ods)|(xlsx?)$/i) {
		my $book = ReadData($res->{_content});
		foreach my $currentRow (Spreadsheet::Read::rows($book->[1])) {
			push( @content, join("\t", @{ $currentRow }) );
		}
	} else {
		@content = split("\n", $res->{_content});
		chomp @content;
	}

	if ($args{DELCOMMENT} =~ /^T/i) {
		@content = grep{ ! /^\#/ } @content;
		@content = grep{ /./ } @content;
	}
	
	return _l2t( \@content );

}

1;
