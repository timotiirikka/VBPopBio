package Bio::Chado::VBPopBio::Util::Subclass;

use strict;
use warnings;

=head1 NAME

Bio::Chado::VBPopBio::Util::Subclass

=head1 SYNOPSIS

The following code sets up an 'Experiment' class which inherits from NaturalDiversity::NdExperiment,
and sets up the correct relationships to other classes.

    package Bio::Chado::VBPopBio::Result::Experiment;
    
    use base 'Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment';
    __PACKAGE__->load_components('+Bio::Chado::VBPopBio::Util::Subclass');
    __PACKAGE__->subclass({ nd_experiment_stocks => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentStock' });


=head1 ACKNOWLEDGEMENTS

Heavily inspired by/modified from:
http://search.cpan.org/~frew/DBIx-Class-Helpers-2.004000/lib/DBIx/Class/Helper/Row/SubClass.pm


=head1 METHODS


=head2 subclass

See SYNOPSIS above.

=cut

sub subclass {
   my $self = shift;
   my $relationships = shift; # rel_name => class
   $self->set_table;
   while (my ($rel, $class) = each %$relationships) {
     my $rel_info = $self->relationship_info($rel);
     die "==== no such relationship '$rel' for '$self' ====\n" unless (defined $rel_info);
     $self->add_relationship(
			     $rel,
			     $class,
			     $rel_info->{cond},
			     $rel_info->{attrs}
			    );
   }
}

=head2 set_table

Private method, not for general use.  Don't really know what this does! (Bob).

=cut

sub set_table {
   my $self = shift;
   $self->table($self->table);
}


1;
