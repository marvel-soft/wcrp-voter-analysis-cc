#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# wcrp-precinct-voter-stats
#
#
#
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#use strict;
use warnings;
$| = 1;
use File::Basename;
use DBI;
use Data::Dumper;
use Getopt::Long qw(GetOptions);
use Time::Piece;
use Math::Round;

=head1 Function
=over
=head2 Overview
	This program will analyze a nevada-county-voter file
		a) file is sorted by precint voter-id ascending
		b)
	Input: 

	Output: a csv file containing the extracted fields
=cut

my $records;

my $inputFile = "clark-voting-file.csv";



my $fileName       = "";
my $voterFile     = "precinct-voters-.csv";
my $voterFileh;
my $voterStatFile = "../prod-in1/precinct-voterstat-.csv";
my $voterStatFileh;
my $printFile      = "precinct-print-.txt";
my $printFileh;

my $csvHeadings        = "";
my @csvHeadings;
my $line1Read    = '';
my $linesRead    = 0;
my $printData;
my $linesWritten = 0;

my $birthDate;
my $regDateOriginal;

my $helpReq         = 0;
my $maxLines        = 0;
my $selParty        = "";
my $skipRecords     = 0;
my $skippedRecords  = 0;


my $generalCount;
my $party;
my $primaryCount;
my $pollCount;
my $totalGENERALS   = 0;
my $totalPRIMARIES  = 0;
my $totalPOLLS      = 0;
my $totalABSENTEE   = 0;
my $totalSTRDEM     = 0;
my $totalMODDEM     = 0;
my $totalWEAKDEM    = 0;
my $percentSTRGRDEM = 0;
my $totalSTRREP     = 0;
my $totalMODREP     = 0;
my $totalWEAKREP    = 0;
my $percentSTRGREP  = 0;
my $totalSTROTHR    = 0;
my $totalMODOTHR    = 0;
my $totalWEAKOTHR   = 0;
my $percentSTRGOTHR = 0;
my $totalOTHR       = 0;
my $totalLEANREP    = 0;
my $totalLEANDEM    = 0;
my $daysTotlRegistered = 0;
my $voter_id = '00000000';

#my $csvRowHash;
my @csvRowHash;
my %csvRowHash = ();
my @values1;
my @values2;
my @date;

my @voterStats;

my $voterStatHeading = "";
my @voterStatHeading = (
	"Voter ID",        "Voter Status",
	"Precinct",        "Last Name",
	"Reg_DateOrig",    "Days Totl Reg", 
	"Age",
	"Generals",        "Primaries",       
	"Polls",           "Absentee",        
	"LeansDEM",        "LeansREP",        "Leans",
	"Rank", 
    "gender",	       "military",

);
my %statLine     = ();
my @statLine;
my $statLine;

#
# main program controller
#
sub main {
	#Open file for messages and errors
	$fileName = basename( $inputFile, ".csv" );
	$printFile = "precinct-print-" . $fileName . ".txt";
	open( $printFileh, ">$printFile" )
	  or die "Unable to open PRINT: $printFile Reason: $!";

	# Parse any parameters
	GetOptions(
		'infile=s'  => \$inputFile,
		'outile=s'  => \$voterFile,
		'lines=i'   => \$maxLines,
		'skip=i'    => \$skipRecords,
		'help!'     => \$helpReq,
	) or die "Incorrect usage!\n";
	if ($helpReq) {
		printLine ("Come on, it's really not that hard. \n");
	}
	else {
		printLine ("My inputfile is: $inputFile. \n");
	}
	unless ( open( INPUT, $inputFile ) ) {
		die "Unable to open INPUT: $inputFile Reason: $! \n";
	}

	# pick out the heading line and hold it and remove end character
	$csvHeadings = <INPUT>;
	chomp $csvHeadings;
	#chop $csvHeadings;

	# headings in an array to modify
	# @csvHeadings will be used to create the files
	@csvHeadings = split( /\s*,\s*/, $csvHeadings );

	# Build heading for new voter stats record
	$voterStatHeading = join( ",", @voterStatHeading );
	$voterStatHeading = $voterStatHeading . "\n";

	#
	# Initialize process loop
	$fileName = basename( $inputFile, ".csv" );

	$voterStatFile = "voterstat-" . $fileName . ".csv";
	printLine ("Voter Statistics file: $voterStatFile \n");
	open( $voterStatFileh, ">$voterStatFile" )
	  or die "Unable to open $voterStatFileh: $voterStatFile Reason: $!";
	print $voterStatFileh $voterStatHeading;

	# Process loop
	# Read the entire input and
	# 1) edit the input lines
	# 2) transform the data
	# 3) write out transformed line
  NEW:
	while ( $line1Read = <INPUT> ) {
		$linesRead++;
		if ( eof(INPUT) ) {
			goto EXIT;
		}
		if ($skipRecords > 0) {
			$skippedRecords = $skippedRecords+1;
			if ($skippedRecords > $skipRecords) {
				$skippedRecords = 0;
			} else {
					goto NEW;
			}
		}
		#
		# Get the data into an array that matches the headers array
		chomp $line1Read;

		# replace commas from in between double quotes with a space
		$line1Read =~ s/(?:\G(?!\A)|[^"]*")[^",]*\K(?:,|"(*SKIP)(*FAIL))/ /g;

		# then create the values array
		@values1 = split( /\s*,\s*/, $line1Read, -1 );

		# Create hash of line for transformation
		@csvRowHash{@csvHeadings} = @values1;

		# determine if record needs writing
		if ( $voter_id eq "000000" ) {
			$voter_id = substr $csvRowHash{"voter_id"} , 0, 4 . "00";
		}
		elsif ( $csvRowHash{"precinct"} != $precinct ) {

			# write new precinctSummary
		printLine ("At line: $linesRead - Precinct Summary for: $precinct \n");
		#	print "At line: $linesRead - Precinct Summary for: $precinct\n";

		#BR - Absent Ballot Received (prior to election, converted to MB after election) 
		#EV - Early Voted 
		#FW - Federal Write-in 
		#MB - Mail Ballot 
		#PP - Polling Place 
		#PV - Provisional Vote 

		voterStats();

		$linesWritten++;
		#
		# For now this is the in-elegant way I detect completion
		if ( eof(INPUT) ) {
			goto EXIT;
		}
		next;
	}
	
	goto NEW;
}
#
# call main program controller
main();
#
# Common Exit
EXIT:
printLine ("<===> Completed conversion of: $inputFile \n");
printLine ("<===> Output available in file: $voterFile \n");
printLine ("<===> Total Records Read: $linesRead \n");
printLine ("<===> Total Records written: $linesWritten \n");

close(INPUT);
#close($voterFileh);
close($voterStatFileh);
close($printFileh);

exit;

#
# create new statLine for voter
#	"Voter ID","Voter Status", "Precinct","Last Name",
# "Age", "Generals","Primaries", "Polls", "Absentee","LeansDEM", "LeansREP","Leans",
# "Rank", "gender", "military","Orig Reg Date","Days Registered", 
#

sub voterStats {
		%statLine = ();
		$statLine{"Voter ID"}  = $csvRowHash{"voter_id"};
		
		$statLine{"Primaries"} = $primaryCount;
		$statLine{"Generals"}  = $generalCount;
		$statLine{"Polls"}     = $pollCount;
		$statLine{"Absentee"}  = $absenteeCount;
		$statLine{"LeansREP"}  = $leansRepCount;
		$statLine{"LeansDEM"}  = $leansDemCount;
		$statLine{"Leans"}     = $leans;
		$statLine{"Rank"}      = $voterRank;
		# Line processed- write it and go on....
		@voterStats = ();
		foreach (@voterStatHeading) {
			push( @voterStats, $statLine{$_} );
		}
		print $voterStatFileh join( ',', @voterStats ), "\n";
		$primaryCount = 0;
		$generalCount = 0;
		$pollCount = 0;
		$absenteeCount = 0;
		$leans = "";
		$voterRank = "";
}

#
# Print report line
#
sub printLine  {
	my $datestring = localtime();
	($printData) = @_;
	#chomp $printData;
	print $printFileh $datestring . ' ' . $printData;
	print $datestring . ' ' . $printData;
}


# routine: evaluateVoter
# determine if reliable voter by voting pattern over last five cycles
# tossed out special elections and mock elections
#  voter reg_date is considered
#  weights: strong, moderate, weak
# if registered < 2 years       gen >= 1 and pri <= 0   = STRONG
# if registered > 2 < 4 years   gen >= 1 and pri >= 0   = STRONG
# if registered > 4 < 8 years   gen >= 4 and pri >= 0   = STRONG
# if registered > 8 years       gen >= 6 and pri >= 0   = STRONG
sub evaluateVoter {
	my $generalPollCount     = 0;
	my $generalAbsenteeCount = 0;
	my $generalNotVote       = 0;
	my $notElegible          = 0;
	my $primaryPollCount     = 0;
	my $primaryAbsenteeCount = 0;
	my $primaryNotVote       = 0;
	$leansRepCount = 0;
	$leansDemCount = 0;
	$leanRep       = 0;
	$leanDem       = 0;
	$generalCount  = 0;
	$primaryCount  = 0;
	$pollCount     = 0;
	$absenteeCount = 0;
	$voterRank     = '';

	#set first vote in list
	my $vote = 55;
	my $cyc;
	#my $daysRegistered = $newLine{"Days Registered"};

  # Likely voter score:
   # if registered < 2 years       gen <= 1 || notelig >= 1            = WEAK
   # if registered < 2 years       gen == 1 ||                         = MODERATE
   # if registered < 2 years       gen == 2 ||                         = STRONG

   # if registered > 2 < 4 years   gen <= 0 || notelig >= 1            = WEAK
   # if registered > 2 < 4 years   gen >= 2 && pri >= 0                = MODERATE
   # if registered > 2 < 4 years   gen >= 3 && pri >= 1                = STRONG

   # if registered > 4 < 8 years   gen >= 0 || notelig >= 1            = WEAK
   # if registered > 4 < 8 years   gen >= 0 && gen <= 2  and pri == 0  = WEAK
   # if registered > 4 < 8 years   gen >= 2 && gen <= 5  and pri >= 0  = MODERATE
   # if registered > 4 < 8 years   gen >= 3 && gen <= 12 and pri >= 0  = STRONG

   # if registered > 8 years   gen >= 0 && gen <= 2 || notelig >= 1    = WEAK
   # if registered > 8 years   gen >= 0 && gen <= 4  and pri == 0      = WEAK
   # if registered > 8 years   gen >= 3 && gen <= 9  and pri >= 0      = MODERATE
   # if registered > 8 years   gen >= 6 && gen <= 12 and pri >= 0      = STRONG

	if ( $daysTotlRegistered < ( 365 * 2 + 1 ) ) {
		if ( $generalCount <= 1 or $notElegible >= 1 ) {
			$voterRank = "WEAK";
		}
		if ( $generalCount >= 1 ) {
			$voterRank = "MODERATE";
		}
		if ( $generalCount >= 2 ) {
			$voterRank = "STRONG";
		}
	}

	# if registered > 2 years and < 4 years>
	if ( $daysTotlRegistered > ( 365 * 2 ) and $daysTotlRegistered < ( 365 * 4 ) ) {
		if ( $generalCount == 0 or  $generalCount == 1 or $notElegible >= 1 ) {
			$voterRank = "WEAK";
		}
		if ( $generalCount >= 2 ) {
			$voterRank = "MODERATE";
		}
		if ( $generalCount >= 3 and $primaryCount >= 1 ) {
			$voterRank = "STRONG";
		}
	}

	# if registered > 4 < 8 years   gen gt 4 && pri gt 3   = STRONG
	if ( $daysTotlRegistered > ( 365 * 4 ) and $daysTotlRegistered < ( 365 * 8 ) ) {
		if ( $generalCount >= 0 or $notElegible >= 1 ) {
			$voterRank = "WEAK";
		}
		if ( $generalCount >= 1 and $generalCount <= 2 and $primaryCount = 0 ) {
			$voterRank = "WEAK";
		}
		if ( $generalCount >= 2 and $generalCount <= 5 and $primaryCount >= 0 )
		{
			$voterRank = "MODERATE";
		}
		if ( $generalCount >= 3 and $generalCount <= 12 and $primaryCount >= 0 )
		{
			$voterRank = "STRONG";
		}
	}

	# if registered > 8 years       gen gt 6 && pri gt 4   = STRONG
	if ( $daysTotlRegistered > ( 365 * 8 ) ) {
		if ( $generalCount >= 0 and $generalCount <= 2 or $notElegible >= 1 ) {
			$voterRank = "WEAK";
		}
		if ( $generalCount >= 0 and $generalCount <= 4 and $primaryCount >= 0 )
		{
			$voterRank = "WEAK";
		}
		if (    $generalCount >= 3
			and $generalCount <= 9
			and $primaryCount >= 0 )
		{
			$voterRank = "MODERATE";
		}
		if ( $generalCount >= 6 and $generalCount <= 12 and $primaryCount >= 0 )
		{
			$voterRank = "STRONG";
		}
	}
	#
	# Set voter strength rating
	#
	if ( $party eq 'DEM' ) {
		if    ( $voterRank eq 'STRONG' )   { $totalSTRDEM++; }
		elsif ( $voterRank eq 'MODERATE' ) { $totalMODDEM++; }
		elsif ( $voterRank eq 'WEAK' )     { $totalWEAKDEM++; }
	}

	elsif ( $party eq 'REP' ) {
		if    ( $voterRank eq 'STRONG' )   { $totalSTRREP++; }
		elsif ( $voterRank eq 'MODERATE' ) { $totalMODREP++; }
		elsif ( $voterRank eq 'WEAK' )     { $totalWEAKREP++; }

	}
	else {
		if    ( $voterRank eq 'STRONG' )   { $totalSTROTHR++; }
		elsif ( $voterRank eq 'MODERATE' ) { $totalMODOTHR++; }
		elsif ( $voterRank eq 'WEAK' )     { $totalWEAKOTHR++; }
	}

	if ( $primaryCount != 0 ) {
		if ( $leansDemCount != 0 ) {
			if ( $leansDemCount / $primaryCount > .5 ) {
				$leanDem = 1;
			}
		}
		if ( $leansRepCount != 0 ) {
			if ( $leansRepCount / $primaryCount > .5 ) {
				$leanRep = 1;
			}
		}
	}
	$totalGENERALS  = $totalGENERALS + $generalCount;
	$totalPRIMARIES = $totalPRIMARIES + $primaryCount;
	$totalPOLLS     = $totalPOLLS + $pollCount;
	$totalABSENTEE  = $totalABSENTEE + $absenteeCount;
	$totalLEANREP   = $totalLEANREP + $leanRep;
	$totalLEANDEM   = $totalLEANDEM + $leanDem;
}

