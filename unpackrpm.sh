#!/bin/bash
# ####################################################################
#
#       ID         : $Id: $
#       Written by : Gosta Malmstrom
# 
#       Comments:
# 
# ####################################################################

# ====================================================================
# Copyright (c) Gosta Malmstrom.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer. 
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. All advertising materials mentioning features or use of this
#    software must display the following acknowledgment:
#    "This product includes software developed by Gosta Malmstrom
#    to make rpm-building easier."
#
# 4. Redistributions of any form whatsoever must retain the following
#    acknowledgment:
#    "This product includes software developed by Gosta Malmstrom
#    to make rpm-building easier."
#
# THIS SOFTWARE IS PROVIDED BY Gosta Malmstrom ``AS IS'' AND ANY
# EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL Gosta Malmstrom OR
# HIS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# ====================================================================


: <<=cut
=pod

=head1 NAME

   unpackrpm - Unpack a rpmfile

=head1 SYNOPSIS

tar2rpm [-n] [-v] [-d unpackdir] rpmfile

=head1 DESCRIPTION

tar2rpm takes a rpm unpack files, dump information in the unpackdir.

The following parameter/options are required :

rpmfile           the rpmfile to unpack

The following parameter/options is accepted :

-v                Run in verbose mode

-d        dir     The directory to unpack things in. default is unpack

=head2 Requirements

This program need rpm to do its work.


=head1 LICENSE

Copyright only


=head1 AUTHOR

Gosta Malmstrom 


=cut

die()
{
    test -n "$*" && echo "$*" >&2
    exit 1
}

cleanup()
{
    if ! $KEEP ; then
	:
    fi
    
}

USAGE="upackrpm: usage: unpackrpm [-v] [-d unpackdir] rpmfile"

#
# Parse parameters
#

VERBOSE=false
UNPACKDIR=unpack

while [ $# -ne 0 ] 
do
        case "$1" in
	-v)	shift; VERBOSE=true ;;
	-d)     shift; UNPACKDIR=$1; shift;;
	--help|-*)	echo "$USAGE" >&2; exit 1 ;;
	*)	break;;
	esac
done

#
# Handle the parameters
#

if [ $# -ne 1 ] ; then 
    echo "$USAGE" >&2
    exit 1
fi

RPMFILE=$1

trap cleanup 0

if $VERBOSE ; then
    set -x
fi

set -e

#
# First - initiate stuff
#

mkdir -p "$UNPACKDIR/root"
(
   cd "$UNPACKDIR/root" >/dev/null 2>&1
   rpm2cpio | cpio -iducm
) < "$RPMFILE"

rpm -ql "$RPMFILE" |
(
   cd "$UNPACKDIR/root" >/dev/null 2>&1
   while read -e -r d ; do
       if [ -d "./$d" ] ; then echo "$d" ; fi
   done > ../dirs
)

rpm -q --requires "$RPMFILE" | sort -u |
    awk '{printf("Requires: %s\n",$0);}' > "$UNPACKDIR/requires"

rpm -q --provides "$RPMFILE" | sort -u |
    awk '{printf("Provides: %s\n",$0);}' > "$UNPACKDIR/provides"

rpm -qi "$RPMFILE" > "$UNPACKDIR/info"

rpm -q --scripts "$RPMFILE" |
    (
	cd "$UNPACKDIR" >/dev/null 2>&1
	awk '
BEGIN {
    currentfile="preinstall"
}
/^preinstall scriptlet/ { currentfile="preinstall"; next ;}
/^postinstall scriptlet/ { currentfile="postinstall"; next ;}
/^preuninstall scriptlet/ { currentfile="preuninstall"; next ;}
/^postuninstall scriptlet/ { currentfile="postuninstall"; next ;}
/^preinstall program/ { next ;}
/^postinstall program/ { next ;}
/^preuninstall program/ { next ;}
/^postuninstall program/ { next ;}
{
    print >> currentfile;
}' 
    )

exit 0
