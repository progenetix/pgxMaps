sub pgSendGoogleTracking {

  use List::MoreUtils qw(any uniq);
  use Net::Google::Analytics::MeasurementProtocol;
  use POSIX qw(strftime);
  use UUID::Tiny;
  use UUID::Tiny ':std';
 
  my $web_root = $ENV{ SERVER_NAME } =~ /\w\w\w/ ? $ENV{ SERVER_NAME } : 'progenetix.org';
  $web_root =~ s/\.\w\w\w\w?$/.org/;
  $web_root =~ s/\/$//;
  my $userAgent = $ENV{ HTTP_USER_AGENT };
  my $userIP = ( $ENV{ HTTP_CF_CONNECTING_IP } =~ /\d\d\d/ ? $ENV{ HTTP_CF_CONNECTING_IP } : $ENV{ REMOTE_ADDR } );
  my $lang = $ENV{ HTTP_ACCEPT_LANGUAGE };
  my $script = fileparse($0);
  $script =~ s/\.cgi//;
 
  my $query = $ENV{ QUERY_STRING };
  $query =~ s/password\=[^\&]*?\&|$//;

  my $googleTrackingID = 'UA-572981-2';;
  my %googleParams = (
    tid => $googleTrackingID,
    ua => $userAgent,
    cid => create_UUID_as_string(UUID_V3, $userIP.'_'.$userAgent),
    uip => $userIP,
  );

  if ($lang =~ /^[^\,]*?(\w\w(\-\w\w)?)/) { $googleParams{ul} = lc($1) }

  my $pageviewParams = {
    dr => $ENV{ HTTP_REFERER },
    dt => $web_root.' cancer genome profiling',
    dp => '/'.$script.'/?'.$query,
    dh => $web_root,
    ds => 'web',
  };

  my $ga = Net::Google::Analytics::MeasurementProtocol->new( %googleParams );
  $ga->send( 'pageview', $pageviewParams);

  foreach (keys %googleParams) { $pageviewParams->{$_} = $googleParams{$_} }
  return  $pageviewParams;

}

1;
