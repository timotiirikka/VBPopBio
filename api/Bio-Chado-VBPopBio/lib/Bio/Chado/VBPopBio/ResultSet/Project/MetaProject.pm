package Bio::Chado::VBPopBio::ResultSet::Project::MetaProject;

use base 'Bio::Chado::VBPopBio::ResultSet::Project';
use Carp;
use strict;

=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Project::MetaProject

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 create_with

Usage:

  # do a chained query to get the stocks you want
  # note that these canned query methods may join the cvterm table a number of times,
  # this is why you have to specify type_2 the second time,
  # you also have to provide table (actually relationship) names to disambiguate *props value column

  $stocks_mali_2005 = $stocks->search_by_project({ 'project.name' => 'UC Davis/UCLA population dataset' })
                             ->search_by_nd_experimentprop({ 'type.name' => 'start date',
                                                             'nd_experimentprops.value' => { like => '2005%' } })
                             ->search_by_nd_geolocationprop({ 'type_2.name' => 'collection site country',
                                                              'nd_geolocationprops.value' => 'Mali' });

  $projects = $schema->projects->search({ name => 'UC Davis/UCLA population dataset' });

  $metaproject = $metaprojects->create_with( { name => 'xyz',
                                               description => 'blah blah',
                                               stocks => $stocks,
                                               projects => $projects,
                                               experimental_factors => [ $factor_cvterm_object ],
                                               object_paths => [ 'object->path' ],
                                             } );

Main method for creating a MetaProject

The stocks argument is a resultset for the stocks you want to add to the new project.

The projects argument tells us which projects to link the new project to (type derives_from).
We can't do this automatically - linking metaproject to all projects that the stocks already
belong to - because some of those may also be metaprojects.  E.g. first we make metaprojects
based on country, then we make some based on year - the stocks already belong to the country
project and we don't want country projects linked to the year projects.

Maybe think about the relationship types more carefully...

The experimental_factors must correspond one-to-one with the object_paths.

=cut

sub create_with {
  my ($self, $args) = @_;

  croak "no name and/or description\n" unless ($args->{name} && $args->{description});
  croak "stocks resultset not given or is empty\n" unless (defined $args->{stocks} && eval { $args->{stocks}->count });
  croak "projects resultset not given or is empty\n" unless (defined $args->{projects} && eval { $args->{projects}->count });

  my $stocks = $args->{stocks};
  my $projects = $args->{projects};

  my $schema = $self->result_source->schema;
  my $cvterms = $schema->cvterms;


  my $metaproject = $self->create( { # will fail if 'name' exists
				    name => $args->{name},
				    description => $args->{description},
				   } );

  # add the experimental factors

  if ($args->{experimental_factors} && ref($args->{experimental_factors}) eq 'ARRAY' &&
      $args->{object_paths} && ref($args->{object_paths}) eq 'ARRAY') {
    for (my $i=0; $i<@{$args->{experimental_factors}} && $i<@{$args->{object_paths}}; $i++) {
      my $factor = $args->{experimental_factors}[$i];
      my $path = $args->{object_paths}[$i];
      $metaproject->find_or_create_related('projectprops',
					   { type => $factor,
					     value => $path,
					   });
    }
  }
  # link it to existing project(s)
  my $derives_from = $cvterms->create_with({ name => 'derives_from', cv => 'relationship' });

  while (my $project = $projects->next) {
    $metaproject->find_or_create_related('project_relationship_subject_projects',
					 {
					  object_project => $project,
					  type => $derives_from,
					 });
  }

  # go through each stock, linking any nd_experiments to the new metaproject
  while (my $stock = $stocks->next) {
    my $experiments = $stock->experiments;
    while (my $experiment = $experiments->next) {
      my $project_link = $experiment->find_or_create_related('nd_experiment_projects',
							     { project => $metaproject,
							     });
    }
  }

  return $metaproject;
}

=head1 AUTHOR

VectorBase, C<< <info at vectorbase.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 VectorBase.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
