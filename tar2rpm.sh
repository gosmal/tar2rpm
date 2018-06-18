#!/bin/bash
# ####################################################################
#
#       ID         : $Id: tar2rpm.sh,v 1.12 2018/06/18 12:31:18 gosta Exp $
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

   tar2rpm - create rpmfile from a tarfile

=head1 SYNOPSIS

tar2rpm [-n] [-v] [-k] [-p buildprefix] [-s specfilename]

tar2rpm [--ver N.N] [--rel N] [--arch noarch/x86_64/i586]

tar2rpm [--sign] [--packager Packager] 

tar2rpm [--dependfile file-with-depends]

tar2rpm [--dirs file-with-list-of-directories]

tar2rpm [--pre file] [--post file] [--preun file] [--postun file]

tar2rpm [--defusr USER] [--defgrp GROUP]

tar2rpm --name RPMNAME tarfile

=head1 DESCRIPTION

tar2rpm creates a rpm from a tarfile. The tarfile is allowed to be compresed with gzip.
If the argument tarfile is a directory tar2rpm assumes that this a location 
with a directory tree to create the rpm. The directory should contain
a filetree from root.

The following parameter/options are required :

--name    RPMNAME the name of the rpm to create

tarfile           the tarfile to create the rpm from

The following parameter/options is accepted :

-n                Dry run 

-v                Run in verbose mode

-k                Keep the specfile and rpmbuild directory

-p        buildprefix  Specify the rpmbuild directory

-s        NAME    Specify the specfile name

--ver     N.N     version number

--rel     N       release number

--arch    noarch/x86_64/i586 rpm architecture

--sign            Sign with PGP

--packager NAME   Builder name

--dependfile file-with-depends provide a section of dependencies

--dirs file-with-list-of-directories file with directories the packet shall own

--pre     file    provide a script run before the installation

--post    file    provide a script run after the installation

--preun   file    provide a script run before the uninstallation

--postun  file    provide a script run after the uninstallation

--defusr  USER    defaultuser

--defgrp  USER    defaultgroup

=head2 Requirements

This program need rpmbuild to do its work.


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


USAGE="tar2rpm: usage: tar2rpm [-n] [-v] [-k] [-p buildprefix] [-s specfilename] --name RPMNAME [--ver N.N] [--rel N] [--arch noarch/x86_64/i586] [--sign] [--packager Packager] [--dependfile file-with-depends] [--dirs file-with-list-of-directories] [--pre file] [--post file] [--preun file] [--postun file] [--defusr USER] [--defgrp GROUP] tarfile|directory"

#
# Parse parameters
#

DRYRUN=false
VERBOSE=false
BUILDPREFIX=/tmp/tar2rpm.$$
SPECFILENAME=""
KEEP=false
SIGN=""
PACKAGER="Config Manager<user.fullname@gmail.com>"
NAME=""
DEPENDFILE=""
DIRSFILE=""
VER=1.0
REL=1
ARCH=noarch

DEFUSR="root"
DEFGRP="root"

PRESCRIPT=""
POSTSCRIPT=""
PREUNSCRIPT=""
POSTUNSCRIPT=""

while [ $# -ne 0 ] 
do
        case $1 in
	-n)	shift; DRYRUN=true ;;
	-v)	shift; VERBOSE=true ;;
	-k)	shift; KEEP=true ;;
	-p)     shift; BUILDPREFIX=$1; shift;;
	-s)     shift; SPECFILENAME=$1; shift;;
	--sign)	shift; SIGN="--sign" ;;
	--name) shift; NAME=$1; shift;;
	--ver)  shift; VER=$1; shift;;
	--rel)  shift; REL=$1; shift;;
	--arch) shift; ARCH=$1; shift;;
	--defusr) 	shift; DEFUSR=$1; shift;;
	--defgrp) 	shift; DEFGRP=$1; shift;;
	--dependfile)   shift; DEPENDFILE=$1; shift;;
	--dirs)         shift; DIRSFILE=$1; shift;;
	--packager)     shift; PACKAGER=$1; shift;;
	--pre)		shift; PRESCRIPT=$1; shift;;
	--post|-P)	shift; POSTSCRIPT=$1; shift;;
	--preun)	shift; PREUNSCRIPT=$1; shift;;
	--postun|-U)	shift; POSTUNSCRIPT=$1; shift;;
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

SOURCEDATA=$1
SOURCEISDIR=false

if [ ! -f "${SOURCEDATA}" ] ; then
    if [ ! -d "${SOURCEDATA}" ] ; then
	die Missing tarfile
    else
	SOURCEISDIR=true
	if [ "${SOURCEDATA}" = "/" ] ; then
	    die tar2rpm cant build from /
	fi
    fi
fi

export BLDTOP=$BUILDPREFIX
UNPACKROOT=$BLDTOP/BUILDROOT/${NAME}

if [ -d "$UNPACKROOT" ] ; then
    die "Target dir : $UNPACKROOT exist"
fi

export RPMSPEC=${BUILDPREFIX}${NAME}.spec
if [ -n "$SPECFILENAME" ] ; then
    export RPMSPEC=$SPECFILENAME
fi

if ! $KEEP ; then
    trap "rm -f $RPMSPEC; rm -rf $BLDTOP" 0
fi

test -n "$NAME"    || die No \$NAME

OPT_V=""
OUTPUT="2> /dev/null"
if $VERBOSE ; then
    OPT_V="-v"
    OUTPUT=""
fi

set -e

#
# First build a file tree to create the rpm from
#

mkdir -p "$UNPACKROOT"

if "$SOURCEISDIR" ; then
    (
	cd "${SOURCEDATA}"
	find . -type f | cpio $OPT_V -pdum "$UNPACKROOT" 2> /dev/null
    )
else
    RUNGZIP=cat
    if expr "${SOURCEDATA}" : '.*gz' > /dev/null ; then
	RUNGZIP=gunzip
    fi

    ${RUNGZIP} < "${SOURCEDATA}" | (cd "$UNPACKROOT"; tar xf -;)
fi

if [ -n "$DIRSFILE" ] ; then
    if [ -f "$DIRSFILE" ] ; then
	cat "$DIRSFILE" | 
	(
	    cd "${UNPACKROOT}"
	    awk '/^[ 	]*$/ {next;} /^[ 	]*#/ {next;} 
	    		{printf "mkdir -p ./%s\n",$NF}' | sh
	)
    else
        die Missing --dirs "$DIRSFILE" file
    fi
fi


#
# Now echo the rpmspec file
#
cat <<EOF > "$RPMSPEC" 
Name: ${NAME}
Summary: Tools/API for Linux
Version: ${VER}
Release: ${REL}
License: Copyright only
Group: Applications/Productivity
BuildArch: $ARCH
BuildRoot: $BLDTOP/BUILDROOT

EOF
if [ -n "$DEPENDFILE" ] ; then
    if [ -f "$DEPENDFILE" ] ; then
	cat "$DEPENDFILE" >> "$RPMSPEC" 
    else
        die Missing --dependfile "$DEPENDFILE" file
    fi
fi
cat <<EOF >> "$RPMSPEC" 

Distribution: None
Vendor: Snake oil INC
Packager: $PACKAGER

%description
This package is automatically built by tar2rpm.

%prep

%build

%install
cd %{_builddir}/BUILDROOT/${NAME} ; find * | cpio $OPT_V -pdum  %{?buildroot} $OUTPUT

# Disable all helpers in install
#unset RPM_BUILD_ROOT

%clean

rm -rf %{?buildroot}

%files
%defattr(-,$DEFUSR,$DEFGRP)

EOF

(
    cd "$UNPACKROOT"
    find . -type f -print | sed 's/\.//'
    echo
) >> "$RPMSPEC"

if [ -n "$DIRSFILE" ] ; then
    cat "$DIRSFILE" | awk '/^[ 	]*$/ {next;} /^[ 	]*#/ {next;} 
		/^[ 	]*%/ {print; next;}
	        {printf "%%dir %s\n",$NF}
		END {printf("\n");}' >> "$RPMSPEC"
fi

if [ -n "$PRESCRIPT" ] ; then
    if [ -f "$PRESCRIPT" ] ; then
	echo "%pre" >> "$RPMSPEC" 
	cat "$PRESCRIPT" >> "$RPMSPEC" 
    else
        die Missing --pre "$PRESCRIPT" file
    fi
fi

if [ -n "$POSTSCRIPT" ] ; then
    if [ -f "$POSTSCRIPT" ] ; then
	echo "%post" >> "$RPMSPEC" 
	cat "$POSTSCRIPT" >> "$RPMSPEC" 
    else
        die Missing --post "$POST" file
    fi
fi

if [ -n "$PREUNSCRIPT" ] ; then
    if [ -f "$PREUNSCRIPT" ] ; then
	echo "%preun" >> "$RPMSPEC" 
	cat "$PREUNSCRIPT" >> "$RPMSPEC" 
    else
        die Missing --preun "$PREUNSCRIPT" file
    fi
fi

if [ -n "$POSTUNSCRIPT" ] ; then
    if [ -f "$POSTUNSCRIPT" ] ; then
	echo "%postun" >> "$RPMSPEC" 
	cat "$POSTUNSCRIPT" >> "$RPMSPEC" 
    else
        die Missing --postun "$POSTUNSCRIPT" file
    fi
fi

cat <<EOF >> "$RPMSPEC" 

%changelog
* Wed Jan 1 2014 $PACKAGER ${VER}-${REL}
- Created version
EOF

RPMBUILDOPTS=""
if $VERBOSE ; then
    cat "$RPMSPEC"
else
    RPMBUILDOPTS="--quiet"
fi    

#
# Create the rpm
#

if ! $DRYRUN ; then
    rpmbuild -bb $SIGN $RPMBUILDOPTS \
	--define="_topdir $BLDTOP" \
	--define="_builddir $BLDTOP" \
	--define="_rpmdir $PWD" "$RPMSPEC"
fi

if $KEEP ; then
    echo "Specfile : $RPMSPEC"
    echo "Buildtop : $BLDTOP"
    echo "Buildcmd :"
    echo rpmbuild -bb $SIGN \
	 "'--define=_topdir $BLDTOP'" \
	 "'--define=_builddir $BLDTOP'" \
	 "'--define=_rpmdir $PWD'" "$RPMSPEC"
else
    rm "$RPMSPEC"
    rm -rf "$BLDTOP"
fi
