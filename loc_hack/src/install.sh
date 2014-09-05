#!/bin/sh
#
# $Id: install.sh 6845 2010-09-23 23:11:24Z NiLuJe $
#
# diff OTA patch script

_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}


MSG_SLLVL_D="debug"
MSG_SLLVL_I="info"
MSG_SLLVL_W="warn"
MSG_SLLVL_E="err"
MSG_SLLVL_C="crit"
MSG_SLNUM_D=0
MSG_SLNUM_I=1
MSG_SLNUM_W=2
MSG_SLNUM_E=3
MSG_SLNUM_C=4
MSG_CUR_LVL=/var/local/system/syslog_level

logmsg()
{
    local _NVPAIRS
    local _FREETEXT
    local _MSG_SLLVL
    local _MSG_SLNUM

    _MSG_LEVEL=$1
    _MSG_COMP=$2

    { [ $# -ge 4 ] && _NVPAIRS=$3 && shift ; }

    _FREETEXT=$3

    eval _MSG_SLLVL=\${MSG_SLLVL_$_MSG_LEVEL}
    eval _MSG_SLNUM=\${MSG_SLNUM_$_MSG_LEVEL}

    local _CURLVL

    { [ -f $MSG_CUR_LVL ] && _CURLVL=`cat $MSG_CUR_LVL` ; } || _CURLVL=1

    if [ $_MSG_SLNUM -ge $_CURLVL ]; then
        /usr/bin/logger -p local4.$_MSG_SLLVL -t "ota_install" "$_MSG_LEVEL def:$_MSG_COMP:$_NVPAIRS:$_FREETEXT"
    fi

    if [ "$_MSG_LEVEL" != "D" ]; then
      echo "ota_install: $_MSG_LEVEL def:$_MSG_COMP:$_NVPAIRS:$_FREETEXT"
      [ -d /mnt/us/localization ] && echo "ota_install: $_MSG_LEVEL def:$_MSG_COMP:$_NVPAIRS:$_FREETEXT" >> /mnt/us/localization/install.log
    fi
}

ORIGFOLDER_LIB=/opt/amazon/ebook/lib
KEYBFOLDER=.
[ -n "$(find /mnt/us/ -maxdepth 1 -name '*.keyb')" ] && KEYBFOLDER=/mnt/us

#Create localization dir at user store
[ -d /mnt/us/localization ] || mkdir /mnt/us/localization

logmsg "I" "update" "Remove JARs"
rm -rf /opt/amazon/ebook/lib/*-sk_SK.jar  >> /mnt/us/localization/install.log 2>&1

logmsg "I" "update" "Copy sk.properties"
update_progressbar 10
cp -f sk.properties /opt/amazon/ebook/config/locales

logmsg "I" "update" "Translate JARs"
update_progressbar 20
/usr/java/bin/cvm -Xms16m -classpath bcel-5.2.jar:K3Translator.jar Translator td4 /opt/amazon/ebook/lib translation.jar en_GB sk_SK >> /mnt/us/localization/install.log 2>&1

logmsg "I" "update" "Translate Keyboard"
update_progressbar 30
/usr/java/bin/cvm -Xms16m -classpath bcel-5.2.jar:K3Translator.jar Translator keyb4 /opt/amazon/ebook/lib/framework-api.jar $KEYBFOLDER es sk_SK >> /mnt/us/localization/install.log 2>&1

#cp -rf /opt/amazon/ebook/lib /mnt/us/localization >> /mnt/us/localization/install.log 2>&1

update_progressbar 40

logmsg "I" "update" "Copy images to img"
tar -xvzf img.tar.gz -C /opt/amazon/ebook >> /mnt/us/localization/install.log 2>&1

update_progressbar 50
logmsg "I" "update" "Copy images to lli"
tar -xvzf low_level_screens.tar.gz -C /opt/amazon >> /mnt/us/localization/install.log 2>&1

update_progressbar 60
logmsg "I" "update" "Copy updatewait wrapper & force using it"
cp -f updatewait /mnt/us/localization/
sed -i 's|^_UPDATE_WAIT=.*$|_UPDATE_WAIT="$(if [ -x /mnt/us/localization/updatewait ]; then echo /mnt/us/localization/updatewait; else echo /usr/sbin/updatewait; fi)"|' /etc/updater.conf >> /mnt/us/localization/install.log 2>&1

update_progressbar 70
logmsg "I" "update" "Copy manual to Kindle"
cp -f manual.mobi /mnt/us/documents/Kindle_Users_Guide.azw
[ -d /opt/amazon/kug/sk/S ] || mkdir -p /opt/amazon/kug/sk/S
cp -f manual.mobi /opt/amazon/kug/sk/S/Kindle_Users_Guide.azw

update_progressbar 80
logmsg "I" "update" "Use the new locale"
sed -i 's/^locale=.*$/locale=sk-SK/' /var/local/java/prefs/com.amazon.ebook.framework/prefs
sed -i 's/^low_level_screens.dir=.*$/low_level_screens.dir=\/opt\/amazon\/low_level_screens\/sk\/600x800/' /var/local/java/prefs/com.amazon.ebook.framework/prefs
sed -i 's/^clippings.file.name=.*$/clippings.file.name=Moje v\\u00FDstri\\u017Eky.txt/' /var/local/java/prefs/com.amazon.ebook.framework/prefs
/usr/bin/install_boot_images /opt/amazon/low_level_screens/sk/600x800

update_progressbar 90
logmsg "I" "update" "Setup dictionaries"
echo "dictionary.list = sk,en,en-GB,de,fr,es,it,pt" > /opt/amazon/dict/conf/sk.conf
sed -i '/^[.]\/documents\/dictionaries\/sk/d' /opt/amazon/data.whitelist
sed -i '/^[.]\/localization/d' /opt/amazon/data.whitelist
echo "./documents/dictionaries/sk" >>/opt/amazon/data.whitelist
echo "./documents/dictionaries/sk/Anglicko-cesky_slovnik.azw" >>/opt/amazon/data.whitelist
echo "./localization" >>/opt/amazon/data.whitelist
echo "./localization/INSTALLED" >>/opt/amazon/data.whitelist
echo "./localization/updatewait" >>/opt/amazon/data.whitelist

[ ! -f /mnt/us/localization/UNINSTALLED ] || rm -f /mnt/us/localization/UNINSTALLED
touch /mnt/us/localization/INSTALLED

logmsg "I" "update" "done"
update_progressbar 100

/usr/sbin/eips -c
/usr/sbin/eips -g success.png

for i in $(seq 1 10)
do
	sleep 1
	/usr/sbin/eips 45 1 $(( 10 - i ))
done

return 0
