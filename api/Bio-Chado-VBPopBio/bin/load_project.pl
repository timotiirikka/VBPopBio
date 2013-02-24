#!/usr/bin/perl -w
# -*- mode: cperl -*-
#
#
# usage: CHADO_DB_NAME=my_chado_instance bin/load_project.pl ../path/to/ISA-Tab-directory
#
# options:
#   --dry-run              : rolls back transaction and doesn't insert into db permanently
#   --json filename        : prints pretty JSON for the whole project to the file
#   --sample-info filename : prints sample external ids, stable ids, and comments to TSV
#

use strict;
use warnings;
use Carp;
use lib 'lib';
use Bio::Chado::VBPopBio;
use JSON;
use Getopt::Long;


my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $projects = $schema->projects;
my $dry_run = 1;
my $json_file;
my $json = JSON->new->pretty;
my $samples_file;

GetOptions("dry-run|dryrun"=>\$dry_run,
	   "json=s"=>\$json_file,
	   "sample-info|samples=s"=>\$samples_file,
    );

my ($isatab_dir) = @ARGV;

$schema->txn_do_deferred
  ( sub {
      my $project = $projects->create_from_isatab({ directory => $isatab_dir });

      if ($json_file) {
	if (open(my $jfile, ">$json_file")) {
	  print $jfile $json->encode($project->as_data_structure);
	  close($jfile);
	} else {
	  $schema->defer_exception("can't write JSON to $json_file");
	}
      }

      if ($samples_file) {
	if (open(my $sfile, ">$samples_file")) {
	  foreach my $stock ($project->stocks) {
	    print $sfile join("\t",
			    $stock->external_id,
			    $stock->stable_id,
			    map { my $c = $_->value; # change "[topic] comment"
				  $c =~ s/^\[//;     # to "topic<tab>comment"
				  $c =~ s/\] /\t/;
				  $c } $stock->multiprops($schema->types->comment))."\n";
	  }
	  close($sfile);
	} else {
	  $schema->defer_exception("can't write sample info to $samples_file");
	}
      }
      $schema->defer_exception("dry-run option - rolling back") if ($dry_run);
    } );

