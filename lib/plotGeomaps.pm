package lib::plotGeomaps;

use Data::Dumper;
use YAML::XS qw(LoadFile);
use readFiles;
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
  my $map_params = read_plot_defaults();

  foreach my $param (keys %{$args}) {
    if (grep{/^$param$/} keys %{$map_params}) {
      my $p_v = $args->{$param};
      if ($p_v =~ /\w/) {
        $map_params->{$param} = $p_v }
    }
  }

  my $self = {
    parameters => $map_params,
    plotid => $map_params->{plotid},
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
    my ($group, $lat, $lon, $size, $label, $link, $type) = @{$g_m};
    my $m_k = $lat."::".$lon;
    $markers->{$m_k}->{size} += $size;
    push(@{$markers->{$m_k}->{items}}, $label);
    print Dumper($group, $label, $markers->{$m_k}->{size}, $markers->{$m_k}->{items});
  }
  # print Dumper(%$markers);


  # return $markers;
  return $pgx->{geomarkers};

}

################################################################################

sub pgx_get_web_geomap {
    
	my $pgx = shift;

	# stop processing now if nothing to do
	if ( scalar keys %{ $pgx->{geomarkers} } < 1 ) {
			return $pgx }

  my $markers = $pgx->{geomarkers};

	# get max marker size
	my @markerS = map{ $markers->{$_}->{size} } keys %{$markers};
	my $markerMax	= (sort {$b <=> $a} @markerS)[0];
	if ($markerMax < 1) {
		$markerMax = 1 }
  my $locsizeF = ( 50000000000 * $pgx->{parameters}->{marker_scale} / $markerMax );
  if (keys %$markers < 2) {
  	$pgx->{parameters}->{marker_type} = 'marker' }
  	
  my @markersJs;
  
  foreach (keys %{$markers}) {

    my $m = $markers->{$_};
    my $title = "<h4>".$m->{group}."</h4>";

    if (@{$m->{items}} > 0) {
      $title .= join("<br/>", @{$m->{items}}) }

    # print Dumper($m);
    
  	if ($m->{type} eq 'marker') {
    	push @markersJs, qq!
L.marker([$m->{lat}, $m->{lon}]).bindPopup('$title')
        ! }
    else {
    	my $radius 	= 	sprintf "%.0f", sqrt($m->{size} / 3.14 * $locsizeF);
    	push @markersJs, qq!
L.circle([$m->{lat}, $m->{lon}], {
    stroke: true,
    color: '$pgx->{parameters}->{bubble_stroke_color}',
    weight: $pgx->{parameters}->{bubble_stroke_weight},
    fillColor: '$pgx->{parameters}->{bubble_fill_color}',
    fillOpacity: $pgx->{parameters}->{bubble_opacity},
    radius: $radius,
    count: $m->{size}
}).bindPopup('$title')
        !
      }  
  }
  
  my $_markersJs 	= 	join(",\n", @markersJs);

  $pgx->{map} = $pgx->{parameters}->{head};
  $pgx->{map} .= 	<< "__HTML__";

<!-- map needs to exist before we load leaflet -->
<div id="map-canvas" style="width: $pgx->{parameters}->{canvas_w_px}px; height: $pgx->{parameters}->{canvas_h_px}px;"></div>

<!-- Make sure you put this AFTER Leaflet's CSS -->
<script src="https://unpkg.com/leaflet\@1.8.0/dist/leaflet.js"
      integrity="sha512-BB3hKbKWOc9Ez/TAwyWxNXeoV9c1v6FIeYiBieIWkpLjauysF18NzgR1MBNBXf8/KABdlkX68nAhlwcDFLGPCQ=="
      crossorigin=""></script>
<script>

  var markers = [
$_markersJs
  ];
  var markersGroup = L.featureGroup(markers);

  // Create the map.
  var map = L.map('map-canvas', { renderer: L.svg() } ).setView([$pgx->{parameters}->{latitude}, $pgx->{parameters}->{longitude}], $pgx->{parameters}->{zoom});

  L.tileLayer('$pgx->{parameters}->{tiles_source}', {
      minZoom: $pgx->{parameters}->{zoom_min},
      maxZoom: $pgx->{parameters}->{zoom_max},
      $pgx->{parameters}->{extra_JS}
      attribution: '$pgx->{parameters}->{attribution}'
  }).addTo(map);

  map.addLayer(markersGroup);
  map.fitBounds(markersGroup.getBounds().pad(0.05));

</script>
__HTML__

  return $pgx;

}

################################################################################

sub read_plot_defaults {

  my $path_of_this_module = File::Basename::dirname( eval { ( caller() )[1] } );
  my $plotPars = LoadFile($path_of_this_module.'/../config/config.yaml');
  return $plotPars->{map_params};

}


1;
