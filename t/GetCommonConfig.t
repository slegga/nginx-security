Global symbol "$mysql" requires explicit package name (did you forget to declare "my $mysql"?) at template line 11, <STDIN> line 2.
Context:
  6: use Mojo::File 'path';
  7: 
  8: # <%= $name %>.pm - <%= $shortdescription %>
  9: 
  10: use Model::<%= $name %>;
  11: % if ($mysql) {
  12: use File::Temp;
  13: my $tempdir = File::Temp->newdir; # Deleted when object goes out of scope
  14: my $tempfile = catfile $tempdir, 'test.db';
  15: my $sql = Mojo::SQLite->new->from_filename($tempfile);
  16: $sql->migrations->from_file('migrations/tabledefs.sql')->migrate;
Traceback (most recent call first):
  File "/home/stein/perl5/perlbrew/perls/perl-5.26.2/lib/site_perl/5.26.2/Mojo/Template.pm", line 166, in "Mojo::Template"
  File "/home/t527081/git/utilities-perl/bin/../../utilities-perl/lib/SH/Code/Template.pm", line 110, in "SH::Code::Template"
  File "/home/t527081/git/utilities-perl/bin/../../utilities-perl/lib/SH/Code/Template/Model.pm", line 52, in "SH::Code::Template::Model"
  File "/home/t527081/git/utilities-perl/bin/template.pl", line 125, in "main"
  File "/home/t527081/git/utilities-perl/bin/template.pl", line 139, in "main"
