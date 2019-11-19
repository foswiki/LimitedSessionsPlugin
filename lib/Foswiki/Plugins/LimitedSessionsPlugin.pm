# Plugin for Foswiki - The Free and Open Source Wiki, https://foswiki.org/
#
# LimitedSessionsPlugin is Copyright (C) 2019 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Plugins::LimitedSessionsPlugin;

use strict;
use warnings;

use Foswiki::Func ();
use CGI::Session ();

our $VERSION = '0.10';
our $RELEASE = '19 Nov 2019';
our $SHORTDESCRIPTION = 'Limit the number of open sessions per users';
our $NO_PREFS_IN_TOPIC = 1;
our $core;

use constant TRACE => 0; # toggle me

sub initPlugin {

  checkSessions();

  return 1;
}

sub checkSessions {

  _writeDebug("called checkSessions");

  my $sessionDir = "$Foswiki::cfg{WorkingDir}/tmp";
  return unless -d $sessionDir;

  my $me = Foswiki::Func::wikiToUserName(Foswiki::Func::getWikiName());
  _writeDebug("me=$me");
  return if $me eq $Foswiki::cfg{DefaultUserLogin} || $me eq $Foswiki::cfg{DefaultUserWikiName};

  my $otherSession;
  my $otherTime;

  CGI::Session->find(
    'driver:File;serializer:Storable',
    sub { 
      my $session = shift;

      my $user = $session->param("AUTHUSER");
      my $time = $session->ctime();
      my $id = $session->id();

      return if !defined($user) || $user ne $me || !defined($time);
      _writeDebug("session id=$id, user=".($user//'undef').", time=".($time//'undef'));

      #_writeDebug($session->dump()) if TRACE;

      if (defined $otherSession) {

        my $delSession;
        if ($time < $otherTime) {
          $delSession = $session;
        } else {
          $delSession = $session;
          $delSession = $otherSession;
          $otherSession = $session;
          $otherTime = $time;
        }

        _writeWarning("old session for user $user found ... deleting ".$delSession->id());
        $delSession->delete();
        $delSession->flush();

      } else {
        if (defined $time) {
          $otherSession = $session;
          $otherTime = $time;
        }
      }
    },
    {
      Directory => $sessionDir,
    }
  );
}

sub _writeDebug {
  return unless TRACE;
  #Foswiki::Func::writeDebug("LimitedSessionsPlugin - $_[0]");
  print STDERR "LimitedSessionsPlugin - $_[0]\n";
}

sub _writeWarning {
  #Foswiki::Func::writeWarning("LimitedSessionsPlugin - $_[0]");
  print STDERR "LimitedSessionsPlugin - $_[0]\n";
}

1;
