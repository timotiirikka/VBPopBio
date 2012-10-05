#!/usr/bin/perl -w

#
# usage: bin/manage_projectprops.pl [ --dry-run -dbname my_chado_db -dbuser henry ] input_file
#
# The following two options also allowed in input file (input file always has precedence)
#
# option defaults: dbname = $ENV{CHADO_DB_NAME}
#                  dbuser = $ENV{USER}
#
# --dry-run prints out (unofficial) project JSON and rolls back transaction
#
# input_file follows this format
# http://search.cpan.org/dist/Config-General/General.pm#CONFIG_FILE_FORMAT
#
# see example in bin/add_projectprops-example.cfg
#
# To ERASE props before adding, see the pre_wipe_all and pre_wipe_indiv top level options
# (e.g. pre_wipe_indiv=VBcv:vis)
#


use strict;
use lib 'lib';  # this is so that I don't have to keep installing BCNA for testing
use Getopt::Long;
use Bio::Chado::VBPopBio;
use Config::General;
use JSON; # for debugging only


my $dbname = $ENV{CHADO_DB_NAME};
my $dbuser = $ENV{USER};
my $dry_run;

GetOptions("dbname=s"=>\$dbname,
	   "dbuser=s"=>\$dbuser,
	   "dry-run|dryrun"=>\$dry_run,
	  );

my ($input_file) = @ARGV;
my $conf = new Config::General(-ConfigFile => $input_file,
			       -SplitPolicy => 'equalsign',
			      );
my %config = $conf->getall;

$dbuser = $config{dbuser} || $dbuser;
$dbname = $config{dbname} || $dbname;

my $dsn = "dbi:Pg:dbname=$dbname";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $dbuser, undef, { AutoCommit => 1 });
my $projects = $schema->projects;
my $projectprops = $schema->resultset('Project::Projectprop');
my $cvterms = $schema->cvterms;
my $json = JSON->new->pretty; # useful for debugging

$schema->txn_do(
		sub {

		  if ($config{pre_wipe_all}) {
		    my $wipe_types = $config{pre_wipe_all};
		    my @wipe_types = ref($wipe_types) eq 'ARRAY' ? @$wipe_types : ($wipe_types);
		    foreach my $wipe_type (@wipe_types) {
		      my ($wipe_type_cv, $wipe_type_name) = split /:/, $wipe_type, 2;
		      die "prop '$wipe_type' didn't contain a colon\n" unless (defined $wipe_type_name);
		      my $wipe_props = $projectprops->search({ 'type.name' => $wipe_type_name,
							       'cv.name' => $wipe_type_cv,
							     },
							     { join => { type => 'cv' } }
							     );
		      warn "Going to wipe ".$wipe_props->count()." projectprops of type $wipe_type (all projects)\n";
		      $wipe_props->delete;
		    }
		  }
		  while (my ($project_name, $project_data) = each %{$config{project}}) {
		    my $project = $projects->find({ name => $project_name }) || die "can't find project by name '$project_name'... exiting!\n";

		    if ($config{pre_wipe_indiv}) {
		      my $wipe_types = $config{pre_wipe_indiv};
		      my @wipe_types = ref($wipe_types) eq 'ARRAY' ? @$wipe_types : ($wipe_types);
		      foreach my $wipe_type (@wipe_types) {
			my ($wipe_type_cv, $wipe_type_name) = split /:/, $wipe_type, 2;
			die "prop '$wipe_type' didn't contain a colon\n" unless (defined $wipe_type_name);
			my $wipe_props = $project->search_related('projectprops',
								  { 'type.name' => $wipe_type_name,
								    'cv.name' => $wipe_type_cv,
								  },
								  { join => { type => 'cv' } }
								 );
			warn "Going to wipe ".$wipe_props->count()." projectprops of type $wipe_type for project id=".$project->project_id()."\n";
			$wipe_props->delete;
		      }
		    }

		    while (my ($prop_name, $prop_value) = each %{$project_data}) {

		      foreach my $prop_value (ref($prop_value) eq 'ARRAY' ? @$prop_value : ( $prop_value )) {
			# print "processing $prop_name = $prop_value\n";

			my ($cv_name, $cvterm_name) = split /:/, $prop_name;

			die "prop '$prop_name' didn't contain a colon\n" unless (defined $cvterm_name);

			$project->create_projectprops( { $cvterm_name => $prop_value },
						       { cv_name => $cv_name,
							 autocreate => 1,
						       }
						     );
		      }
		    }

		    if ($dry_run) {
		      #my $json = $json->encode($project->as_data_structure);
		      #print $json;
		      #print "\n============================\n";
		      print "Project ".$project->project_id()." will have ".$project->projectprops->count()." props including external_id etc (dry run for ".substr($project->name(),0,30)."...)\n";
		    }
		  }


		  $schema->txn_rollback if ($dry_run);
		});
