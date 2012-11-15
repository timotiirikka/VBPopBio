package Bio::Chado::VBPopBio::Util::Phenote;

use strict;
use warnings;
use Carp;

use base 'Exporter';
our @EXPORT_OK = qw(parse_phenote);  # symbols to export on request

=head1 NAME

Bio::Chado::VBPopBio::Util::Phenote

=head1 SYNOPSIS

Parser for phenote files.

=head2 parse_phenote

  Usage: $hashref = Bio::Chado::VBPopBio::Util::Phenote::parse_phenote($phenote_file_name, $isa_parser, $key_column_name);

  Args: file name (without directory)
        Bio::Parser::ISATab object (this knows the directory)
        string (column name to hash the file data on)

  Returns: hash column_name => array_ref of row hashes

=cut

sub parse_phenote {
  my ($phenote_file_name, $isa_parser, $key_column_name) = @_;
  my $phenote_file_fullpath = $isa_parser->directory.'/'.$phenote_file_name;
  my $tsv_parser = $isa_parser->tsv_parser;

  open(my $tsv_fh, $phenote_file_fullpath) or croak "couldn't open phenotye-format file: $phenote_file_fullpath";
  # use the headers from the first line
  $tsv_parser->column_names($tsv_parser->getline($tsv_fh));
  # get an array_ref of all the row hashrefs
  my $rows = $tsv_parser->getline_hr_all($tsv_fh);
  # now hash this on $key_column_name
  my $result = {};
  foreach my $row (@$rows) {
    if (defined (my $key = $row->{$key_column_name})) {
      push @{$result->{$key}}, $row;
    }
  }
  close($tsv_fh);
  return $result;
}
