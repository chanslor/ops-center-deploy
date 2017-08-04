#!/bin/bash
#
# Install OpsCenter bins
#
#
# author: michael.chanslor@gmail.com
#
# desc:  Install OpsCenter bins
#
# Copyright (C) 2017  Michael D. Chanslor
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2
# of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#
#
CURRENT_BIN="OpsCenterAgent.Solaris.sparc.xxxxx.xxxxx.zip"
HOST=`/bin/hostname`
DATE=`date +%s`
OS=`uname -s`
WORK_DIR="/var/tmp"
OPS_CENTER_IP="xxx.xxx.x.x"
PASSWORD_FILE="/var/tmp/xVM/mypasswd"
OPS_USER="root"



if [ "$OS" = "SunOS" ]; then
echo "Running SunOS...."
YES="/bin/yes"
BINDIR="/opt/SUNWxvmoc/bin"
#HaHa, all SunOS systems have IP and hostname in hosts file.
IP=`grep \`uname -n\` /etc/hosts | head -1 | awk ' { print $1 } '`
fi

if [ "$OS" = "Linux" ]; then
echo "Running LINUX...."
YES="/usr/bin/yes"
BINDIR="/opt/sun/xvmoc/bin"
fi

#Current ver from pkginfo -l SUNWscn-update-util
CURRENT_CACO="12.3.2.1113"

OS=`uname -s`
if [ "$OS" = "SunOS" ]; then
	echo "Running SunOS...."
else
	echo "Your are not running SunOS..."
	echo "This script only for for SunOS"
	exit 1
fi

register_the_system()
{

if [[ ( -d $BINDIR) && ( -f $PASSWORD_FILE )  ]]; then

     echo
     echo " Attempting to register with Ops Center..."
     cd $BINDIR
     echo "Running Stop"
     ./agentadm stop
     echo "Running unconfigure"
     ./agentadm unconfigure
     echo "Running configure"
     echo
          if [ "$OS" = "SunOS" ]; then
          $YES | $BINDIR/agentadm configure -u $OPS_USER -p $PASSWORD_FILE -a $IP -x $OPS_CENTER_IP
          else
          $YES | $BINDIR/agentadm configure -u $OPS_USER -p $PASSWORD_FILE -x $OPS_CENTER_IP
          fi
     echo "configure complete."
     echo

else
echo "You must create a PASSWORD_FILE with the password for USER"
fi
}

unzip_bins()
{

if [ -d $WORK_DIR/OpsCenterAgent ] ; then
	echo "cleaning old OpsCenterAgent dirs..."
	cd $WORK_DIR && rm -rf OpsCenterAgent
	rm -f SunConnectionAgent
fi
		
if [ -f $CURRENT_BIN ] ; then
	echo "Unzipping Agent..."
	cd $WORK_DIR && unzip -q $CURRENT_BIN
else

	echo "Error unzipping|file not found"
	exit 1
fi

}

install_bins()
{
if [ -d $WORK_DIR/OpsCenterAgent ] ; then
	cd $WORK_DIR/OpsCenterAgent
	./install
else
	echo "Could NOT find install dir."
fi
}

is_it_registered()
{
REGCURRENT=$(keytool --list -keystore /var/opt/sun/xvm/security/jsse/scn-agent/truststore -storepass trustpass | egrep  "4E:4B:47:5C:C6:9F:6F:3E:E7:37:AF:D4:0E:73:AD:4A:3A:FB:0C:23|99:8C:2A:06:0F:53:90:DE:6D:B9:0A:2E:C7:A7:67:74:08:3E:B0:0F" | wc -l)

   if [[ "$REGCURRENT" -eq 2 ]]; then
   echo ":: System is registered  ::"
   else
   echo "keystore incorrect, Trying registration."
   register_the_system
   fi
}

check_for_installed_bins()
{
if [ -f /usr/lib/cacao/bin/cacaoadm ] ; then
	echo "OpsCenter bins are installed."
else
	echo "Could not find bins"
	install_bins
fi
}

check_current()
{
# Is CACO present?
if [ -f /usr/lib/cacao/bin/cacaoadm ] ; then #CACO=`/usr/lib/cacao/bin/cacaoadm -V`
	CACO=`pkginfo -l SUNWscn-update-util | grep VERSION | awk -F, ' { print $1 } ' | awk ' { print $2 } '`
	#echo $CACO

	if [ $CACO = $CURRENT_CACO ] ; then
		echo "CACO version $CACO is CURRENT."
		exit 0
	else
		echo "CACO version outdated or missing"
		unzip_bins
		echo "CACO version installing."
		install_bins
		
		exit 0
	fi
else
	echo "Error Updating."
fi
}


###############
#### MAIN #####
###############

#Are bins installed
check_for_installed_bins

#If so then check registration
is_it_registered

#If so then is it current?
check_current




