.PHONY : all tar rpm clean check

RPMVER=$(shell git tag | tail -1)

ifdef VER
    RPMVER=$(VER)
endif

RPMREL=1
ifneq ($(RPMVER), $(shell git describe))
    RPMREL=$(shell date +%s)
endif

all :
	@echo "make rpm ?"

tar2rpm.1 : tar2rpm.sh
	pod2man tar2rpm.sh > tar2rpm.1

tar : tar2rpm.1
	rm -rf usr
	mkdir -p usr/bin usr/share/man/man1
	cp tar2rpm.sh usr/bin/tar2rpm
	chmod +x usr/bin/*
	cd usr/bin; ln -s tar2rpm tar2rpm.link
	cp tar2rpm.1  usr/share/man/man1
	gzip usr/share/man/man1/*
	tar czvf tar2rpm.tar.gz usr
	rm -rf usr

rpm : tar
	echo 'Requires: rpm-build' > depends
	sh tar2rpm.sh --name tar2rpm --ver $(RPMVER) --rel $(RPMREL) \
	  --dependfile depends \
	  --arch noarch \
	  --packager "User Fullname <user.fullname@gmail.com>" \
	  tar2rpm.tar.gz


check :
	shellcheck -e SC2002 tar2rpm.sh

clean :
	rm -rf i586 i386 x86_64 noarch
	rm -f tar2rpm.tar.gz *.rpm tar2rpm.1 depends
	rm -f `find . -name '*~' -type f`

