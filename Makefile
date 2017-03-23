MyProductName = "NFS-Win"
MyCompanyName = "Navimatics Corporation"
MyDescription = "NFS for Windows"
MyVersion = 1.0.$(shell date '+%y%j')

PrjDir	= $(shell pwd)
BldDir	= .build
DistDir = $(BldDir)/dist
SrcDir	= $(BldDir)/src
RootDir	= $(BldDir)/root
WixDir	= $(BldDir)/wix
Status	= $(BldDir)/status
BinExtra= #bash ls mount

export PATH := /cygdrive/c/Program Files (x86)/WiX Toolset v3.10/bin:$(PATH)

goal: $(Status) $(Status)/done

$(Status):
	mkdir -p $(Status)

$(Status)/done: $(Status)/dist
	touch $(Status)/done

$(Status)/dist: $(Status)/wix
	mkdir -p $(DistDir)
	cp $(shell cygpath -aw $(WixDir)/nfs-win-$(MyVersion).msi) $(DistDir)
	touch $(Status)/dist

$(Status)/wix: $(Status)/nfs-win
	mkdir -p $(WixDir)
	cp nfs-win.wxs $(WixDir)/
	candle -nologo -arch x86 -pedantic\
		-dMyProductName=$(MyProductName)\
		-dMyCompanyName=$(MyCompanyName)\
		-dMyDescription=$(MyDescription)\
		-dMyVersion=$(MyVersion)\
		-o "$(shell cygpath -aw $(WixDir)/nfs-win.wixobj)"\
		"$(shell cygpath -aw $(WixDir)/nfs-win.wxs)"
	heat dir $(shell cygpath -aw $(RootDir))\
		-nologo -dr INSTALLDIR -cg C.Main -srd -ke -sreg -gg -sfrag\
		-o $(shell cygpath -aw $(WixDir)/root.wxs)
	candle -nologo -arch x86 -pedantic\
		-dMyProductName=$(MyProductName)\
		-dMyCompanyName=$(MyCompanyName)\
		-dMyDescription=$(MyDescription)\
		-dMyVersion=$(MyVersion)\
		-o "$(shell cygpath -aw $(WixDir)/root.wixobj)"\
		"$(shell cygpath -aw $(WixDir)/root.wxs)"
	light -nologo\
		-o $(shell cygpath -aw $(WixDir)/nfs-win-$(MyVersion).msi)\
		-ext WixUIExtension\
		-b $(RootDir)\
		$(shell cygpath -aw $(WixDir)/root.wixobj)\
		$(shell cygpath -aw $(WixDir)/nfs-win.wixobj)
	touch $(Status)/wix

$(Status)/nfs-win: $(Status)/root nfs-win.c
	gcc -o $(RootDir)/bin/nfs-win nfs-win.c
	strip $(RootDir)/bin/nfs-win
	touch $(Status)/nfs-win

$(Status)/root: $(Status)/make
	mkdir -p $(RootDir)/{bin,dev/{mqueue,shm},etc}
	(cygcheck $(SrcDir)/fuse-nfs/fuse/.libs/fuse-nfs; for f in $(BinExtra); do cygcheck /usr/bin/$$f; done) |\
		tr -d '\r' | tr '\\' / | xargs cygpath -au | grep '^/usr/bin/' | sort | uniq |\
		while read f; do cp $$f $(RootDir)/bin; done
	cp $(SrcDir)/fuse-nfs/fuse/.libs/fuse-nfs $(RootDir)/bin
	strip $(RootDir)/bin/fuse-nfs
	for f in $(BinExtra); do cp /usr/bin/$$f $(RootDir)/bin; done
	cp $(PrjDir)/fstab $(RootDir)/etc
	touch $(Status)/root

$(Status)/make: $(Status)/config
	cd $(SrcDir)/libnfs && make
	cd $(SrcDir)/fuse-nfs && make
	touch $(Status)/make

$(Status)/config: $(Status)/reconf
	cd $(SrcDir)/libnfs && ./configure
	cd $(SrcDir)/fuse-nfs && ./configure CFLAGS="$(shell pkg-config fuse --cflags) -I$$PWD/../libnfs/include" LDFLAGS="-L$$PWD/../libnfs/lib"
	touch $(Status)/config

$(Status)/reconf: $(Status)/patch
	cd $(SrcDir)/libnfs && autoreconf -i
	cd $(SrcDir)/fuse-nfs && autoreconf -i
	touch $(Status)/reconf

$(Status)/patch: $(Status)/clone
	cd $(SrcDir)/libnfs && for f in $(PrjDir)/patches/libnfs/*.patch; do patch -p1 <$$f; done
	cd $(SrcDir)/fuse-nfs && for f in $(PrjDir)/patches/fuse-nfs/*.patch; do patch -p1 <$$f; done
	touch $(Status)/patch

$(Status)/clone:
	mkdir -p $(SrcDir)
	git clone $(PrjDir)/libnfs $(SrcDir)/libnfs
	git clone $(PrjDir)/fuse-nfs $(SrcDir)/fuse-nfs
	touch $(Status)/clone

clean:
	git clean -dffx
