#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use GitLab::API::v4;
use Getopt::Long;
use Log::Any::Adapter ('Stdout');
use Log::Any qw($log);

my %opts=(
    name_regex=>'.*',
    keep_n=>'10',
    older_than=>'1month',
);
GetOptions (\%opts,
    "url=s",
    "token=s",
    "project=s",
    "name_regex:s",
    "keep_n:i",
    "older_than:s",
);

my $api = GitLab::API::v4->new(
    url           => $opts{url},
    private_token => $opts{token},
);

my $regreps = $api->paginator(
    'registry_repositories_in_project',
    $opts{project},
)->all();

for my $regrep (@$regreps) {
    $log->infof("Deleting old images from registry for project %s", $regrep->{name});
    eval {
        my $rv = $api->bulk_delete_registry_repository_tags($opts{project}, $regrep->{id}, {
            map { $_ => $opts{$_}} qw(name_regex keep_n older_than)
        } );
        if ($rv) {
            $log->notice($rv);
        }
    };
    $log->error($@) if $@;
}

=pod

=head1 SYNOPSIS

  gitlab_bulk_delete_containers.pl --project 42 --url https://your-gitlab/api/v4/ --token XXX \
                                   --name_regex '^[^m].*'                                     \
                                   --keep_n 10                                                \
                                   --older_than 1month

Walk through all L<GitLab|https://gitlab.com> registry repositories of
the project with the id 42 and delete container images older than
month, but keep at least 10, which do not start with 'm'.

=head1 DESCRIPTION

When you build containers and push them into the GitLab registry,
these containers stay there forever, taking up considerable amounts of
disk space, and also cluttering the user interface.

While GitLab offers an
L<API|https://docs.gitlab.com/ee/api/container_registry.html#delete-registry-repository-tags-in-bulk>
to bulk-delete containers, this API only works for one registry
repository. If using a monorepo, you will end up with a lot of
registry repositories, making this API not very useful.

Hence this script: It fetches all registry repositories for the given
project, and then calls the bulk-delete endpoint on them.

=head1 INSTALLATION

For now, I do not publish this (very little) code on CPAN, so you have to checkout this repo:

  git clone https://github.com/domm/GitLab-BulkDeleteContainers.git

=head2 Old-school

If you have a proper Perl installed on your system, just install the
dependencies. I recommend using L<local::lib> and C<cpanminus> or
C<cpm>:

  cpm install
  # OR
  cpanm -L local --installdeps .

=head2 Docker

... TODO ...


=head1 OPTIONS

=head3 --project

The project id (as an integer, not the weird URI-Escaped string..)

Required.

=head3 --url

The URL of the gitlab instance you want to use. Include the path to Capi/v4>!

Required.

=head3 --token

An access token. Get it from "User Settings" -> "Access Token", make sure to allow the scope C<api>.

Required.

=head3 --name_regex

TODO --name_regex='^[^m].*' keeps master (and all other tags starting with 'm', but I could not figure out a re2 regex that matches /^(?!master)/

=head3 --keep_n

TODO

=head3 --older_than

TODO


=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head2 THANKS

=over

=item  L<validad.com|https://validad.com> for allowing me to publish this interal tool.

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.


