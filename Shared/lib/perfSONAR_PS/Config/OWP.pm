#
#      $Id: OWP.pm 2640 2009-03-20 01:21:21Z zurawski $
#
#########################################################################
#									#
#			   Copyright (C)  2002				#
#	     			Internet2				#
#			   All Rights Reserved				#
#									#
#########################################################################
#
#	File:		perfSONAR_PS::Config::OWP.pm
#
#	Author:		Jeff Boote
#			Internet2
#
#	Date:		Tue Sep 24 11:23:49  2002
#
#	Description:	
#
#	Usage:
#
#	Environment:
#
#	Files:
#
#	Options:
package perfSONAR_PS::Config::OWP;
require 5.005;
require Exporter;
use strict;
use FindBin;
use POSIX;
use Fcntl qw(:flock);
use FileHandle;
use vars qw(@ISA @EXPORT $VERSION);
use perfSONAR_PS::Config::OWP::Helper;
use perfSONAR_PS::Config::OWP::Conf;
use perfSONAR_PS::Config::OWP::Utils;

@ISA = qw(Exporter);
@EXPORT = qw(daemonize setids);

$perfSONAR_PS::Config::OWP::REVISION = '$Id: OWP.pm 2640 2009-03-20 01:21:21Z zurawski $';
$VERSION = '1.0';

sub setids{
	my(%args)	= @_;
	my ($uid,$gid);
	my ($unam,$gnam);

	$uid = $args{'USER'} if(defined $args{'USER'});
	$gid = $args{'GROUP'} if(defined $args{'GROUP'});

	# Don't do anything if we are not running as root.
	return if($> != 0);

	die "Must set User option! (Running as root is folly!)"
		if(!$uid);

	# set GID first to ensure we still have permissions to.
	if(defined($gid)){
		if($gid =~ /\D/){
			# If there are any non-digits, it is a groupname.
			$gid = getgrnam($gnam = $gid) or
				die "Can't getgrnam($gnam): $!";
		}
		elsif($gid < 0){
			$gid = -$gid;
		}
		die("Invalid GID: $gid") if(!getgrgid($gid));
		$) = $( = $gid;
	}

	# Now set UID
	if($uid =~ /\D/){
		# If there are any non-digits, it is a username.
		$uid = getpwnam($unam = $uid) or
			die "Can't getpwnam($unam): $!";
	}
	elsif($uid < 0){
		$uid = -$uid;
	}
	die("Invalid UID: $uid") if(!getpwuid($uid));
	$> = $< = $uid;

	return;
}

sub daemonize{
	my(%args)	= @_;
	my($dnull,$umask) = ('/dev/null',022);
	my $fh;

	$dnull = $args{'DEVNULL'} if(defined $args{'DEVNULL'});
	$umask = $args{'UMASK'} if(defined $args{'UMASK'});

	if(defined $args{'PIDFILE'}){
		$fh = new FileHandle $args{'PIDFILE'}, O_CREAT|O_RDWR|O_TRUNC;
		unless($fh && flock($fh,LOCK_EX|LOCK_NB)){
			die "Unable to lock pid file $args{'PIDFILE'}: $!";
		}
		$_ = <$fh>;
		if(defined $_){
			my ($pid) = /(\d+)/;
			chomp $pid;
			die "$FindBin::Script:$pid still running..."
				if(kill(0,$pid));
		}
	}

	open STDIN, "$dnull"	or die "Can't read $dnull: $!";
	open STDOUT, ">>$dnull"	or die "Can't write $dnull: $!";
	if(!$args{'KEEPSTDERR'}){
		open STDERR, ">>$dnull"	or die "Can't write $dnull: $!";
	}

	defined(my $pid = fork)	or die "Can't fork: $!";

	# parent
	exit if $pid;

	# child
	$fh->seek(0,0);
	$fh->print($$);
	undef $fh;
	setsid			or die "Can't start new session: $!";
	umask $umask;

	return 1;
}

#
# Hacks to fix incomplete CGI.pm
#
package CGI;
sub script_filename{
    return $ENV{'SCRIPT_FILENAME'};
}

1;
