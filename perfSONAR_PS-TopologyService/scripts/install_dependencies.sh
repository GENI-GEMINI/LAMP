#!/bin/bash

MAKEROOT=""
if [[ $EUID -ne 0 ]]; then
    MAKEROOT="sudo "
fi

$MAKEROOT cpan Carp
$MAKEROOT cpan Config::General
$MAKEROOT cpan Cwd
$MAKEROOT cpan Data::Dumper
$MAKEROOT cpan Data::UUID
$MAKEROOT cpan Digest::MD5
$MAKEROOT cpan English
$MAKEROOT cpan Error
$MAKEROOT cpan Exporter
$MAKEROOT cpan Fcntl
$MAKEROOT cpan File::Basename
$MAKEROOT cpan FindBin
$MAKEROOT cpan Getopt::Long
$MAKEROOT cpan HTTP::Daemon
$MAKEROOT cpan IO::File
$MAKEROOT cpan LWP::Simple
$MAKEROOT cpan LWP::UserAgent
$MAKEROOT cpan Log::Log4perl
$MAKEROOT cpan Module::Load
$MAKEROOT cpan Net::Ping
$MAKEROOT cpan POSIX
$MAKEROOT cpan Params::Validate
$MAKEROOT cpan Time::HiRes
$MAKEROOT cpan XML::LibXML
$MAKEROOT cpan base
$MAKEROOT cpan lib
$MAKEROOT cpan warnings
