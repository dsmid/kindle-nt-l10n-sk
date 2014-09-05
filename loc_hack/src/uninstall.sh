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
      [ -d /mnt/us/localization ] && echo "ota_install: $_MSG_LEVEL def:$_MSG_COMP:$_NVPAIRS:$_FREETEXT" >> /mnt/us/localization/uninstall.log
    fi
}

# Hack specific config (name and when to start/stop)
ORIGFOLDER_LIB=/opt/amazon/ebook/lib

#Create localization dir at user store
[ -d /mnt/us/localization ] || mkdir /mnt/us/localization

logmsg "I" "update" "Remove ru.properties"
update_progressbar 10
rm -f /opt/amazon/ebook/config/locales/sk.properties

logmsg "I" "update" "Remove sk.conf & whitelist entries"
update_progressbar 20
rm -f /opt/amazon/dict/conf/sk.conf
sed -i '/^[.]\/documents\/dictionaries\/sk/d' /opt/amazon/data.whitelist
sed -i '/^[.]\/localization/d' /opt/amazon/data.whitelist

update_progressbar 30
logmsg "I" "update" "Remove the manual"
rm -rf /opt/amazon/kug/sk >> /mnt/us/localization/uninstall.log 2>&1

update_progressbar 40
logmsg "I" "update" "Remove images from img/ui"
rm -rf /opt/amazon/ebook/img/ui/sk >> /mnt/us/localization/uninstall.log 2>&1

update_progressbar 60
logmsg "I" "update" "Remove images from LowLevelImages"
rm -rf /opt/amazon/low_level_screens/sk >> /mnt/us/localization/uninstall.log 2>&1

update_progressbar 70
logmsg "I" "update" "Remove JARs"
rm -rf /opt/amazon/ebook/lib/*-sk_SK.jar  >> /mnt/us/localization/uninstall.log 2>&1

update_progressbar 80
logmsg "I" "update" "Restore updater.conf"
sed -i 's|^_UPDATE_WAIT=.*$|_UPDATE_WAIT="/usr/sbin/updatewait"|' /etc/updater.conf  >> /mnt/us/localization/uninstall.log 2>&1

update_progressbar 90
logmsg "I" "update" "Use the original locale"
sed -i 's/^locale=.*$/locale=en-US/' /var/local/java/prefs/com.amazon.ebook.framework/prefs
sed -i 's/^low_level_screens.dir=.*$/low_level_screens.dir=\/opt\/amazon\/low_level_screens\/600x800/' /var/local/java/prefs/com.amazon.ebook.framework/prefs
sed -i 's/^clippings.file.name=.*$/clippings.file.name=My Clippings.txt/' /var/local/java/prefs/com.amazon.ebook.framework/prefs
/usr/bin/install_boot_images /opt/amazon/low_level_screens/600x800

logmsg "I" "update" "done"
update_progressbar 100

[ ! -f /mnt/us/localization/INSTALLED ] || rm -f /mnt/us/localization/INSTALLED
touch /mnt/us/localization/UNINSTALLED

return 0
