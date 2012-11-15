package Bio::Chado::VBPopBio::Result::Linker::ProjectStock;

=head1 NAME

Bio::Chado::VBPopBio::Result::Linker::ProjectStock

=head1 DESCRIPTION

Virtual table to provide project to stocks linkage.  Data actually comes from projectprops with negative ranks.

=cut

use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('project_stock');
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(
      "SELECT project_id, -1*rank AS stock_id FROM projectprop WHERE rank < 0 AND type_id = ?"
  );
__PACKAGE__->add_columns(
    'project_id' => {
      data_type => 'integer',
    },
    'stock_id' => {
      data_type => 'integer',
    },
  );

=head2 stock

Type: belongs_to

Related object: L<Bio::Chado::VBPopBio::Result::Stock>

=cut

__PACKAGE__->belongs_to(
  "stock",
  "Bio::Chado::VBPopBio::Result::Stock",
  { stock_id => "stock_id" },
);

=head2 project

Type: belongs_to

Related object: L<Bio::Chado::VBPopBio::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "Bio::Chado::VBPopBio::Result::Project",
  { project_id => "project_id" },
);
