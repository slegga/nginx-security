package Model::GetCommonConfig;
use Mojo::Base -base, -signatures;
use Mojo::SQLite;
use open ':encoding(UTF-8)';




=head1 NAME

Model::GetHypnotoadConfig.pm - Return the hypnotoad hash config for filename. Read $HOME/etc/hypnotoad.yml

=head1 DESCRIPTION

<DESCRIPTION>

=head1 ATTRIBUTES

=head2 dbfile

Name of dbfile

=head2 sqlite

Default to a new Mojo::SQLite object

=head2 db

Default to a new Mojo::SQLite::Database object

=cut

has dbfile => $ENV{HOME}.'/etc/GetHypnotoadConfig.db';
has sqlite => sub {
	my $self = shift;
	if ( -f $self->dbfile) {
		return Mojo::SQLite->new()->from_filename($self->dbfile);
	} else {
		my $path = path($self->dbfile)->dirname;
		if (!-d "$path" ) {
			$path->make_path;
		}
		return Mojo::SQLite->new("file:".$self->dbfile);
	#	die "COULD NOT CREATE FILE ".$self->dbfile if ! -f $self->dbfile;
	}

};
has db => sub {shift->sqlite->db};


option 'dryrun!', 'Print to screen instead of doing changes';

=head1 METHODS

=head2 read

...

=cut

sub read {
    my $self = shift;
    my $res = $self->db->query(q|select a, b from c|);
    die $res->stderr if ($res->err);
}

sub write {
    my $self = shift;
    my $hash =shift;
    my @keys = keys %$hash;
    my @values = values %$hash;
    my $res = $self->db->query('replace into c('.join(',',@keys).')', @values);
    die $res->stderr if ($res->err);
}


__PACKAGE__->new(options_cfg=>{extra=>1})->main();
