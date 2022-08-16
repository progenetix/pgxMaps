package lib::plotGeomaps;

use Data::Dumper;
use YAML::XS qw(LoadFile);

use plotMakeParameters;
use readFiles;
use writeFiles;
require Exporter;
@ISA    =   qw(Exporter);
@EXPORT =   qw(
  new
  pgx_get_web_geomap
  read_plot_defaults
);

########    ####    ####    ####    ####    ####    ####    ####    ####    ####
########    ####    ####    ####    ####    ####    ####    ####    ####    ####
########    ####    ####    ####    ####    ####    ####    ####    ####    ####


sub new {

  my $class = shift;
  my $args = shift;
  $args =   lib::plotMakeParameters::args_modify_plot_parameters(read_plot_defaults(), $args);
  my $self = {
    parameters => $args,
    plotid => $args->{plotid},
    map => q{},
  };

  bless $self, $class;
  return $self;

}

########    ####    ####    ####    ####    ####    ####    ####    ####    ####
########    ####    ####    ####    ####    ####    ####    ####    ####    ####
########    ####    ####    ####    ####    ####    ####    ####    ####    ####

sub _aggregate_geomarkers {
    
  my $pgx = shift;

  my $markers = {};
  foreach my $g_m (@{$pgx->{geomarkers}}) {
    my ($title, $lat, $lon, $size, $type) = @{$g_m};
    my $m_k = $lat."::".$lon;
    $markers->{$m_k}->{size} += $size;
    # print Dumper($markers->{$m_k});
  }
  # print Dumper(%$markers);


  # return $markers;
  return $pgx->{geomarkers};

}

################################################################################

sub pgx_get_web_geomap {
    
	my $pgx = shift;

	# stop processing now if nothing to do
	if ( scalar @{$pgx->{geomarkers}} < 1 ) {
			return $pgx }

  my $markers = $pgx->_aggregate_geomarkers();

	# get max marker size
	my @markerS = map{ $_->[3] } @{$markers};
	my $markerMax	= (sort {$b <=> $a} @markerS)[0];
	if ($markerMax < 1) {
		$markerMax = 1 }
  my $locsizeF = ( 50000000000 * $pgx->{parameters}->{map_marker_scale} / $markerMax );
  if (@{$markers} < 2) {
  	$pgx->{parameters}->{map_marker_type} = 'marker' }
  	
  my @markersJs;
  
  foreach my $marker (@{$markers}) {

    my ($title, $lat, $lon, $size, $type) = @{$marker};

    $title .= '<hr/><a href="http://progenetix.org">link</a>';

    if (! grep{ $type eq $_ } qw(circle marker)) {
    	$type = $pgx->{parameters}->{map_marker_type} }
    
  	if ($type eq 'marker') {
    	push @markersJs, qq!
L.$type([$lat, $lon]).bindPopup('$title').addTo(map)
        ! }
    else {
    	my $radius 	= 	sprintf "%.0f", sqrt($size / 3.14 * $locsizeF);
    	push @markersJs, qq!
L.$type([$lat, $lon], {
    stroke: true,
    color: '$pgx->{parameters}->{map_bubble_stroke_color}',
    weight: $pgx->{parameters}->{map_bubble_stroke_weight},
    fillColor: '$pgx->{parameters}->{map_bubble_fill_color}',
    fillOpacity: $pgx->{parameters}->{map_bubble_opacity},
    radius: $radius,
    count: $size
}).bindPopup('$title').addTo(map)
        !
      }  
  }
  
  my $_markersJs 	= 	'' . join(';', @markersJs) . '';

  $pgx->{map} = $pgx->{parameters}->{map_head};

  $pgx->{map} .= 	<< "__HTML__";

<!-- map needs to exist before we load leaflet -->
<div id="map-canvas" style="width: $pgx->{parameters}->{size_plotimage_w_px}px; height: $pgx->{parameters}->{size_plotimage_h_px}px;"></div>

<!-- Make sure you put this AFTER Leaflet's CSS -->
<script src="https://unpkg.com/leaflet\@1.8.0/dist/leaflet.js"
      integrity="sha512-BB3hKbKWOc9Ez/TAwyWxNXeoV9c1v6FIeYiBieIWkpLjauysF18NzgR1MBNBXf8/KABdlkX68nAhlwcDFLGPCQ=="
      crossorigin=""></script>
<script>
  // Create the map.
  var map = L.map('map-canvas', { renderer: L.svg() } ).setView([$pgx->{parameters}->{map_latitude}, $pgx->{parameters}->{map_longitude}], $pgx->{parameters}->{map_zoom});

  L.tileLayer('$pgx->{parameters}->{map_tiles}', {
      minZoom: $pgx->{parameters}->{map_zoom_min},
      maxZoom: $pgx->{parameters}->{map_zoom_max},
      $pgx->{parameters}->{map_extra_JS}
      attribution: '$pgx->{parameters}->{map_attribution}'
  }).addTo(map);

  $_markersJs;
</script>
__HTML__

  return $pgx;

}

################################################################################

sub read_plot_defaults {

  my $path_of_this_module = File::Basename::dirname( eval { ( caller() )[1] } );
  my $plotPars = LoadFile($path_of_this_module.'/../config/plotdefaults.yaml');
  return $plotPars;

}


1;
