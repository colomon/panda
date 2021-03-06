#!/usr/bin/env perl6
use v6;
use lib 'ext/File__Tools/lib';
use Shell::Command;

# Find old state file
my ($prefix, $state-file);
for grep(*.defined, %*ENV<DESTDIR>, %*CUSTOM_LIB<site home>) {
    if "$_/panda/state".path.e {
        $prefix = $_;
        $state-file = "$_/panda/state";
    }
}

if not $state-file.defined {
    say "No need to rebootstrap, running normal bootstrap";
    shell 'perl6 bootstrap.pl';
    exit 0;
}

# Save a copy of the old state file to be written *after* bootstrapping again
my $old-state = slurp $state-file;

# Find modules that were installed by request
# (as opposed to just for dependency resolution)
my @modules;
given open($state-file) {
    for .lines() -> $line {
        my ($name, $state) = split /\s/, $line;
        next if $name eq any(<File::Tools JSON::Tiny Test::Mock panda>);
        if $state eq 'installed' {
            @modules.push: $name;
        }
    }
    .close;
}

# Clean old directories, boostrap a fresh panda,
# and reinstall all manually-installed modules
rm_rf "$prefix/lib";
rm_rf "$prefix/panda";
shell 'perl6 bootstrap.pl';
say "==> Reinstalling @modules[]";
shell "perl6 bin/panda install @modules[]";

# Save the backup state file back to $prefix/panda/
spurt "$state-file.bak", $old-state if $old-state;
