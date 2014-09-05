#! /bin/sh

ulimit -c 100000000

. ../../config

PKGNAME="${HACKNAME}"
PKGVER="${VERSION}"

recode -f utf8..flat < citaj-ma-utf8.txt > citaj-ma.txt
unix2dos citaj-ma.txt
cp -f ../../K3Translator/K3Translator.jar ./
tar cvzf low_level_screens.tar.gz -C ../../images --exclude .svn low_level_screens
tar cvzf img.tar.gz -C ../../images --exclude .svn img

# Prepare our files for this specific kindle model...
ARCH=${PKGNAME}_${PKGVER}_k4

# Build install update
./kindletool create ota2 -d k4 -d k4b install.sh bcel-5.2.jar K3Translator.jar translation.jar default.keyb sk.properties low_level_screens.tar.gz img.tar.gz success.png manual.mobi updatewait update_${ARCH}_install.bin

# Build uninstall update
./kindletool create ota2 -d k4 -d k4b uninstall.sh update_${ARCH}_uninstall.bin

# Pack the updates
rm -f ../${PKGNAME}_${PKGVER}.zip
zip ../${PKGNAME}_${PKGVER}.zip *.bin citaj-ma.txt
rm -f *.bin
