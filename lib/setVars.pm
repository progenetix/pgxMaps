use CGI qw(param multi_param);

sub pgSetPaths {

  use YAML::XS 'LoadFile';
	use File::Basename;

  my %args = @_;

  $args{LOC_ROOT} //= $ENV{DOCUMENT_ROOT};
  $args{WEB_ROOT} //= q{};

  # definition of ubiquitous path and file defaults in a hash =>  reference

  my %PD = ();

  # script root modification due to the modules being used by non-CGIs, which can inject their
  # location here

  # roots have to be defined

  # loc_fRoot   full local path, e.g. used by R libraries for the working dir and src
  # web_rRoot   web link path relative to the web root (usually empty string)
  # web_fRoot   web path incl. server address; set to www.progenetix.org, e.g. for exported SVGs

  $PD{web_rRoot} = $args{WEB_ROOT};
  $PD{web_rRoot} =~ s/www\.//;
  $PD{web_fRoot} = $ENV{SERVER_NAME} =~ /\w\w\w/ ? $ENV{SERVER_NAME} : 'progenetix.org';
  ($PD{web_pgSite} = $PD{web_fRoot}) =~ s/^(\w\w\w\w?\.)?arraymap(\.\w\w\w\w?)$/progenetix$2/i;
  foreach (
    qw(
      web_pgSite
      web_fRoot
    )
  ) { $PD{$_}   =   'https://'.$PD{ $_ } } 

  $PD{web_rRoot}    =~  s/\.net$/.org/;
  $PD{web_fRoot}    =~  s/info\.//;
  $PD{web_fRoot}    =~  s/\.net$/.org/;
  $PD{web_fRoot}    =~  s/\/$//;
  ($PD{web_tld}    	=   $PD{web_fRoot})	=~	s/^.*?\.(\w{3,4})$/\1/;

  $PD{web_infoRoot} =  	'https://docs.progenetix.org';
  if ($PD{web_fRoot} =~ /test/) {
  	$PD{web_infoRoot} =  	'https://docs.progenetix.test' }

  # unique directory name from timestamp, for temporary web directories

  my $pathvar .= "$^T"."$$";

  $PD{scriptName} = fileparse($0);

  if ($PD{scriptName} =~  /^(\w+?)(\.\w\w\w?)?$/) {
    $pathvar        =  '_'.$1.'_'.$pathvar;
  }

  # root paths can be injected, or are generated from fixed values or server environment
  my $thisdir   =   File::Basename::dirname( eval { ( caller() )[1] } );

  $PD{loc_fRoot}    =   $thisdir.'/../../../Documents';
  $PD{loc_cgi}      =   $thisdir.'/../..';
  $PD{web_cgi}      =   '';

  foreach (
    qw(
      collab
      css
      Sites
      tmp
    )
  ) {
    $PD{'loc_'.lc($_)} = $PD{loc_fRoot}.'/'.$_;
    $PD{'web_'.lc($_)} = $PD{web_fRoot}.'/'.$_;
  }

  # there are config files - apache master copy, YAML ..., in a protected
  # directory
  $PD{loc_config} = '../config';
  
  my $confLoc   =   LoadFile($PD{loc_config}.'/pgdefaults.yaml');  
  foreach (keys %$confLoc) {
    $PD{$_}     =   $confLoc->{$_} }

  return \%PD;
}

################################################################################

sub setValueDefaults {

  # VD_r is a hash reference for all ubiquitous variables
  # those may be used in the CGIs and also exported into the R scripts (printing them to a list)
  # general defaults

  my %VD;

  $VD{users}    =   [ qw() ];
  $VD{techniques}       =   [ qw(cCGH aCGH WES WGS) ];
  $VD{genome}   =   'GRCh38';
  $VD{genedb}   =   'genespans';

  # plot parameters; the color_scheme may be defined through the web form,
  # with replacement of the current colors through the ones defined by a function

  $VD{datasetLabel}     =   q{};
  $VD{color_scheme}     =   'yellowblue';
  $VD{plot_bgcolor_hex}     =   '#ffffff';
  $VD{plot_areacolor_hex}   =   '#f3f9ff';
  $VD{sample_number_max}    =   1000;
  $VD{geodist}  =   20;

  # selection of the chromosomes to be plotted overall, e.g. 1:22 or 1:24
  $VD{chr2plot} =   join(',', 1..22, 'X');
  $VD{intlevel} =   '1MBP';
  $VD{sample_number_min}        =   5;

  # connections plot
  $VD{conn_opacity}     =   0.2;

  # threshold for p-value of KM survival plots
  $VD{threshold_pvalue} =   0.1;

  # search field dummies
  $VD{edit}         =   q{};
  $VD{tags_m}       =   [];
  $VD{update}       =   q{};

  # canonical file names in subsets etc.

  %VD   =  (
    %VD,
    progenetix_json_file    =>  'progenetix.json',
    progenetix_txt_file =>  'progenetix.tab',
    segments_frequency_filename =>  'segFrequencies.tab',
    segmatrix_file      =>  'segMatrix.tab',
    survmatrix_file     =>  'survMatrix.tab',
    segments_filename   =>  'segments,cn.tsv',
    probes_filename     =>  'probes,cn.tsv',
    segments_extended_filename  =>  'segments_extended.tab',
    sampleorder_file    =>  'subsetorder.tab',
    sampleorder_file    =>  'sampleorder.tab',
  );

  return \%VD;

}

################################################################################

sub pg_oldschool_to_PGX_args {

  my $oldschool =   shift;
  my $pgxargs   =   {};
  foreach (qw(genome chr2plot)) {
    $pgxargs->{'-'.$_}  =   $oldschool->{pgV}->{$_};
  }
  $pgxargs->{'-value_plot_y_max'}  =   $oldschool->{pgV}->{maxy};
  $pgxargs->{'-size_plotimage_w_px'}  =   $oldschool->{pgV}->{imgw};
  $pgxargs->{'-plotregions'}    =   join(',', @{ $oldschool->{pgV}->{plotregion_m} });

  if ($oldschool->{pgV}->{markers_m}) {
    my @markers;
    foreach (@{ $oldschool->{pgV}->{markers_m} }) {
      if ( /^(?:\[(.+?)\])? *?(?:chro?)?(\w\d?\:\d+?\-\d+?)$/) {
        my $marker    =   $2;
        my $label     =   $1;
        if ($label =~ /\w/) { $marker .= ':'.$label }
        push(@markers, $marker);
      }
    }
    $pgxargs->{'-markers'}    =   join(',', @markers);
  }

  return $pgxargs;

}

################################################################################

sub pgInitializeCGI {

  my %args = @_;

  $args{pgV} = setValueDefaults();
  $args{pgV} = pgReadParam(%args);
  $args{google_params} = pgSendGoogleTracking();

  return %args;

}

################################################################################

sub pgReadParam {

  my %args = @_;

  foreach my $key (param()) {

    my $pgVkey = lc($key);

    if ($key =~ /_m$/) {

      # list style form fields have the tag "_m" and are stored in list context
      # additionally, comma-concatenated values are split

      $args{pgV}->{$pgVkey} = [ map{ split(/(<hr\/?>)|\n|\r|(<li?\/?>)/, $_) } param($key) ];

      # removal of everything (i.e. subsettext ...) following a square bracket is based on the
      # collection of multiple ICD etc. values in a common text area using the menu style
      # pop-up selector
      # now
      if ( grep( /$key/,  qw(icdm_m icdt_m pmid_m platform_m text_m) ) ) {
        $args{pgV}->{$pgVkey}   =   [ apply{ $_ =~ s/(\w+?) ?\[.*?$/$1/ } @{ $args{pgV}->{$key} } ] }

      # lists values are comma-separated when from a text field => split ','
      # but in geo_m there are city, country, continent => skip splitting
      if ($key !~ /geo_m/ ) {
        $args{pgV}->{$pgVkey}   =   [ uniq(map{ split(',', $_) } @{ $args{pgV}->{$key} }) ] }

    } else {

      $args{pgV}->{$pgVkey}     =   param($key);

  }}

  return $args{pgV};

}


1;
