#! /usr/bin/perl

    #                Obtain Google Page Rank for URL

    #               by John Walker  --  February 2006
    #     	    	        Version 1.0


    use strict;
    use warnings;

    use WWW::Google::PageRank;

    #   If $restrictReferer is non-null, it will be used as a regular
    #   expression used to test the HTTP_REFERER field we receive from
    #   the Web server.  This can (and should) be used to restrict access
    #   to this script to pages originating at the site where it's hosted.
    #   If your site has several aliases (ratburger.org, ratburger.net,
    #   etc.) or permits access by IP address or IP address range, you'll
    #   have to craft a regular expression which matches everything you
    #   may see as a referer.

    my $restrictReferer = '';
#    my $restrictReferer =
#    	    qr{^http://((((www|server\d)\.)?
#    	       fourmilab\.
#	       (ch|com|net|org|to|bz|info))|
#	       193\.8\.230\.\d+)/}x; 	# FOURMILAB EXAMPLE

    #   If $restrictURI is non-null, it will be used as a regular
    #   expression used to test the URI query field we receive with the
    #	request.  This allows blocking requests for the page rank of
    #	other site's pages via our server, even if they go to the length
    #	of forging a an HTTP_REFERER which makes it past the
    #	$restrictReferer test.

    my $restrictURI = '';
#    my $restrictURI = qr{^http://((((www|server\d)\.)?fourmilab\.(ch|com|net|org|to|bz|info))|193\.8\.230\.\d+)/}; 	# FOURMILAB PRODUCTION

    #	Permitted API keys.  If you don't specify any API keys
    #	you will not be able to make general requests via the
    #	Web form.
     my %API_keys;
#     my %API_keys = ( 'chef@ratburger.org', 1,
#                      'distims@gostak.org', 1
#                    );
    
    #	Set $imgpath to the directory containing the pagerank*.png images
    
    my $imgpath = 'images';

    #   You shouldn't need to change anything below this line.

    my $prog = "page_rank";

    my $debug = 0;
    my $text = 0;
    my $uri = '';
    my $apikey = '';
    my $IPaddress;
    my $query;
    my $cmdline = 0;

    if (defined($ENV{REQUEST_METHOD})) {
    	parse_query_string();
	$IPaddress = trim($ENV{REMOTE_ADDR});

	$debug = 1 if defined($ENV{WWW_debug});

	if (defined($ENV{WWW_uri})) {
    	    $uri = $ENV{WWW_uri};
	    if ($uri eq 'referer') {
		$uri = $ENV{HTTP_REFERER};
		$ENV{WWW_uri} = "Referer=$uri";	    	# For debugging
	    }
	}

	$apikey = $ENV{WWW_apikey} if defined($ENV{WWW_apikey});

	$text = $ENV{WWW_text} if defined($ENV{WWW_text});
	
	$query = $ENV{SCRIPT_NAME};
    } else {
    	$cmdline = 1;
	if ($#ARGV != 0) {
	    print(STDERR "Usage: $0 url\n");
	    exit(0);
	}
	$uri = $ARGV[0];
    }
   
    if ($debug) {
    	generate_debug_output();
    }
        
    #	If API key supplied and incorrect, that's it for this request
    
    if (($apikey ne '') && !$API_keys{$apikey}) {
    	stumble("$prog: Invalid API key \"$apikey\" from $IPaddress\n");
    }
    
    #	If command line request or API key supplied and valid, skip restriction checks
    
    if ((!$cmdline) && (!$API_keys{$apikey}) && ($uri ne '')) {

	#	If $restrictReferer is defined, test the HTTP_REFERER environment
	#	variable for a match.  If it fails to match die, leaving only a
	#	message in the server error log as evidence.  The (ab)user who
	#	is trying to hijack the page rank meter will see only a "500 server
	#	misconfiguration" error, and will have no idea why the access
	#	actually failed.

	if (($restrictReferer ne '') &&
    	    ((!defined($ENV{'HTTP_REFERER'})) || (!($ENV{'HTTP_REFERER'} =~ m/$restrictReferer/)))) {
	    $ENV{'HTTP_REFERER'} = '(undef)' if !defined($ENV{'HTTP_REFERER'});
    	    stumble("$prog: Possible hijack attempt from $IPaddress; HTTP_REFERER=$ENV{'HTTP_REFERER'} failed to match\n");
	}

	#	If $restrictURI is defined, test the URI request
	#	for a match.  If it fails to match die, leaving only a
	#	message in the server error log as evidence.  The (ab)user who
	#	is trying to hijack the page rank meter will see only a "500 server
	#	misconfiguration" error, and will have no idea why the access
	#	actually failed.

	if (($restrictURI ne '') &&
    	    ($uri !~ m/$restrictURI/)) {
    	    stumble("$prog: Possible hijack attempt from $IPaddress; WWW_uri=$uri failed to match\n");
	}
    }
    
    if ($debug) {
    	generate_debug_trailer();
 	exit(0);
    }
    
    #	Everything looks OK--go ahead and ask for the page rank

    my ($rank, @result) = ('', []);
    
    if ($uri ne '') {
    	my $pr = WWW::Google::PageRank->new;
    	($rank, @result) = $pr->get($uri);
    }
    
    #	If command line request, print page rank (-1 if not available)
    #	and exit.
    
    if ($cmdline) {
    	$rank = -1 if !defined($rank);
	print("$rank\n");
	exit(0);
    }
    
    #	HTML request: call emit_html_result() to generate reply page
    
    if (($uri eq '') || defined($ENV{WWW_html})) {
    	emit_html_result();
	exit(0);
    }
    
    #	Text request: generate text/plain document with page rank result
    
    if ($text) {
    	$rank = -1 if !defined($rank);
    	print <<"EOD";
Content-type: text/plain\r
\r
$rank
EOD
    	exit(0);
    }
    
    #	Image request: copy image corresponding to rank to standard output
 
    binmode(STDOUT);
    
    print("Content-type: image/png\r\n");
    print("\r\n");
  
    #	Open the image file for the page rank determined and copy it
    #	to standard output.

    $rank = 'q' if !defined($rank);
    open(IMG, "<$imgpath/pagerank$rank.png") || die("Cannot open $imgpath/pagerank$rank.png");
    binmode(IMG);
    
    my $io;
    
    while (read(IMG, $io, 512)) {
    	print($io);
    }
    
    close(IMG);
    
    #	Generate HTML form result when html query argument is present
    
    sub emit_html_result {
    	my $title = 'Google Page Rank Query';
	
	if ($uri ne '') {
	    $title .= ": " . quote_HTML($uri);
	}
    
    	print <<"EOD";
Content-type: text/html\r
\r
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>$title</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<style type="text/css">
    body {
        margin-left: 15%;
        margin-right: 10%;
	background-color: #FFFFFF;
	color: #000000;
	text-align: center;
    }
</style>
</head>
<body>
EOD

	my $quri = quote_HTML($uri);
    	if (defined($rank)) {
	    if ($rank ne '') {
	    	print("<h3>Google page rank for $quri: $rank</h3>\n");
	    } else {
	    	print("<h3>Enter URL to obtain Google page rank</h3>\n");
	    }
	} else {
	    print("<h3>Google page rank for $uri unavailable.</h3>\n");
	}
	
	my $apik = '</p><p>API&nbsp;Key:&nbsp;<input type="text" name="apikey" size="24" value="" />';
	if ($apikey ne '') {
	    $apik = '<input type="hidden" name="apikey" value="' . $apikey . '" />';
	}

    	print <<"EOD";
	
	<form method="get" action="$query">
	<p>
	    <input type="hidden" name="html" value="1" />
	    Address:&nbsp;<input type="text" name="uri" size="60" maxlength="1024" value="$quri" />
	    $apik
	</p>
	<p>
	    <input type="submit" value=" Get Page Rank " /> &nbsp;
	    <input type="reset" value=" Reset " />
	</p>
	</form>
</body>
</html>
EOD
    }

    #	Parse the CGI QUERY_STRING argument (placed in the environment when
    #	the Web server launches this script).  This function sets environment
    #	variables named WWW_varname for each field in the form with value the
    #	unquoted contents of each field.  This rather odd way of returning
    #	results ("Why not just use a regular hash?") is used to maintain
    #	compatibility with the UNCGI program.  A Perl script which previously
    #	required execution under the control of UNCGI may be run stand-alone
    #	by calling this function at the top.  This halves the number of processes
    #	the server must fork in order to process the request, and is one
    #	fewer thing for the beleaguered system administrator to install.

    sub parse_query_string {
    	my ($rmeth, @args, $instream, $var, $varname, $value);

	$rmeth = $ENV{'REQUEST_METHOD'};    # Request method ("GET" or "POST")
	$rmeth =~ tr/a-z/A-Z/;	    	    # Just in case server doesn't shout
	if ($rmeth eq 'GET') {
	    @args = split(/&/, $ENV{'QUERY_STRING'});
	} elsif ($rmeth eq 'POST') {
	    read(STDIN, $instream, $ENV{'CONTENT_LENGTH'});
	    @args = split(/&/, $instream);
	}
	foreach $var (@args) {
	    ($varname, $value) = split(/=/, $var);
	    $varname = unescape_URL($varname);
	    $value = unescape_URL($value);
	    #   The following code provides protection against server-side includes being
	    #   embedded in CGI arguments.  No sane site runs server-side includes, in my
	    #   opinion.  If you require this protection, uncomment these lines, but note
	    #   that it's (remotely) possible that binary encoded arguments may be corrupted
	    #   by this filter.
	    #	    #	Elide any server-side includes a mischevious user may have
	    #	    #	embedded in a value string.  This protects against mayhem if
	    #	    #	the value is included in an HTML reply.
	    #	    $value =~ s/<!--(.|\n)*-->//g;

	    #	Define an "uncgi" compatible environment variable for
	    #	each name/value pair.

	    $ENV{"WWW_$varname"} = $value;
	}
    }

    #	Escape a URL

    sub escape_URL {
    	my ($s) = @_;

    	$s =~ s/([^A-Za-z0-9\$\-_\.\!\*\(\)])/sprintf("%%%02X", ord($1))/eg;
	return $s;
    }

    #	Unescape a URL-encoded string

    sub unescape_URL {
    	my ($s) = @_;

	$s =~ tr/+/ /;
	$s =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

	return $s;
    }

    #	Trim string by removing leading and trailing white space

    sub trim {
    	my ($s) = @_;

	if (!defined($s)) {
	    $s = '';
	}
	$s =~ s/^\s+//;     	# Delete leading blanks
	$s =~ s/\s+$//;     	# Delete trailing blanks
	return $s;
    }
    
    #	Escape text to appear in HTML.  This is used only for regular
    #	text content, not quoted attribute strings, and thus leaves
    #	quotes intact.
    
    sub quote_HTML {
    	my ($s) = @_;
	
	$s =~ s/&/&amp;/g;
	$s =~ s/</&lt;/g;
	$s =~ s/>/&gt;/g;
	return $s;
    }

    #	Generate the debugging report
    
    use Data::Dumper;
    
    sub generate_debug_output {
    	$Data::Dumper::Sortkeys = 1;
    	print("Content-type: text/html\r\n");
   	print("\r\n");

    	print <<"EOD";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
</head>
<body>
<pre>
EOD
	
	print(Data::Dumper->Dump([\%ENV], ['ENV']));
	
	if (@result) {
	    print(Data::Dumper->Dump([\@result], ['result']));
	}
    }
    
    sub generate_debug_trailer {
	print("</pre>\n</body>\n</html>\n");
    }
    
    #	The stumble() function handles request errors which are fatal
    #	in normal mode but which we simple report when $debug is
    #	defined.
    
    sub stumble {
    	my ($message) = @_;
	
	if ($debug) {
	    print("\nFATAL ERROR: $message");
	} else {
	    die($message);
	}
    }
