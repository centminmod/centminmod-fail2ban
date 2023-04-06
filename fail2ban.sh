#!/bin/bash
######################################################
# written by George Liu (eva2000) centminmod.com
# https://github.com/centminmod/centminmod-fail2ban
######################################################
# variables
#############
VER=0.13
DT=$(date +"%d%m%y-%H%M%S")
# https://github.com/fail2ban/fail2ban/tags
FAIL2BAN_TAG="1.0.2"

USERIP=$(last -i | grep "still logged in" | awk '{print $3}' | uniq | xargs)
SERVERIPS=$(curl -4s https://geoip.centminmod.com/v4 | jq -r '.ip')
IGNOREIP=$(echo "ignoreip = 127.0.0.1/8 ::1 $USERIP $SERVERIPS")
DIR_TMP='/svr-setup'
######################################################
# functions
#############
CENTOSVER=$(awk '{ print $3 }' /etc/redhat-release)

KERNEL_NUMERICVER=$(uname -r | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }')

if [ "$CENTOSVER" == 'release' ]; then
    CENTOSVER=$(awk '{ print $4 }' /etc/redhat-release | cut -d . -f1,2)
    if [[ "$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
    elif [[ "$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1)" = '8' ]]; then
        CENTOS_EIGHT='8'
    elif [[ "$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1)" = '9' ]]; then
        CENTOS_NINE='9'
    fi
fi

if [[ "$(cat /etc/redhat-release | awk '{ print $3 }' | cut -d . -f1)" = '6' ]]; then
    CENTOS_SIX='6'
fi

# Check for Redhat Enterprise Linux 7.x
if [ "$CENTOSVER" == 'Enterprise' ]; then
    CENTOSVER=$(awk '{ print $7 }' /etc/redhat-release)
    if [[ "$(awk '{ print $1,$2 }' /etc/redhat-release)" = 'Red Hat' && "$(awk '{ print $7 }' /etc/redhat-release | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
        REDHAT_SEVEN='y'
    fi
fi

if [[ -f /etc/system-release && "$(awk '{print $1,$2,$3}' /etc/system-release)" = 'Amazon Linux AMI' ]]; then
    CENTOS_SIX='6'
fi

# ensure only el8+ OS versions are being looked at for alma linux, rocky linux
# oracle linux, vzlinux, circle linux, navy linux, euro linux
EL_VERID=$(awk -F '=' '/VERSION_ID/ {print $2}' /etc/os-release | sed -e 's|"||g' | cut -d . -f1)
if [ -f /etc/almalinux-release ] && [[ "$EL_VERID" -eq 8 || "$EL_VERID" -eq 9 ]]; then
  CENTOSVER=$(awk '{ print $3 }' /etc/almalinux-release | cut -d . -f1,2)
  if [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '8' ]]; then
    CENTOS_EIGHT='8'
    ALMALINUX_EIGHT='8'
  elif [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '9' ]]; then
    CENTOS_NINE='9'
    ALMALINUX_NINE='9'
  fi
elif [ -f /etc/rocky-release ] && [[ "$EL_VERID" -eq 8 || "$EL_VERID" -eq 9 ]]; then
  CENTOSVER=$(awk '{ print $4 }' /etc/rocky-release | cut -d . -f1,2)
  if [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '8' ]]; then
    CENTOS_EIGHT='8'
    ROCKYLINUX_EIGHT='8'
  elif [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '9' ]]; then
    CENTOS_NINE='9'
    ROCKYLINUX_NINE='9'
  fi
elif [ -f /etc/oracle-release ] && [[ "$EL_VERID" -eq 8 || "$EL_VERID" -eq 9 ]]; then
  CENTOSVER=$(awk '{ print $5 }' /etc/oracle-release | cut -d . -f1,2)
  if [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '8' ]]; then
    CENTOS_EIGHT='8'
    ORACLELINUX_EIGHT='8'
  elif [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '9' ]]; then
    CENTOS_NINE='9'
    ORACLELINUX_NINE='9'
  fi
elif [ -f /etc/vzlinux-release ] && [[ "$EL_VERID" -eq 8 || "$EL_VERID" -eq 9 ]]; then
  CENTOSVER=$(awk '{ print $4 }' /etc/vzlinux-release | cut -d . -f1,2)
  if [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '8' ]]; then
    CENTOS_EIGHT='8'
    VZLINUX_EIGHT='8'
  elif [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '9' ]]; then
    CENTOS_NINE='9'
    VZLINUX_NINE='9'
  fi
elif [ -f /etc/circle-release ] && [[ "$EL_VERID" -eq 8 || "$EL_VERID" -eq 9 ]]; then
  CENTOSVER=$(awk '{ print $4 }' /etc/circle-release | cut -d . -f1,2)
  if [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '8' ]]; then
    CENTOS_EIGHT='8'
    CIRCLELINUX_EIGHT='8'
  elif [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '9' ]]; then
    CENTOS_NINE='9'
    CIRCLELINUX_NINE='9'
  fi
elif [ -f /etc/navylinux-release ] && [[ "$EL_VERID" -eq 8 || "$EL_VERID" -eq 9 ]]; then
  CENTOSVER=$(awk '{ print $5 }' /etc/navylinux-release | cut -d . -f1,2)
  if [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '8' ]]; then
    CENTOS_EIGHT='8'
    NAVYLINUX_EIGHT='8'
  elif [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '9' ]]; then
    CENTOS_NINE='9'
    NAVYLINUX_NINE='9'
  fi
elif [ -f /etc/el-release ] && [[ "$EL_VERID" -eq 8 || "$EL_VERID" -eq 9 ]]; then
  CENTOSVER=$(awk '{ print $3 }' /etc/el-release | cut -d . -f1,2)
  if [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '8' ]]; then
    CENTOS_EIGHT='8'
    EUROLINUX_EIGHT='8'
  elif [[ "$(echo $CENTOSVER | cut -d . -f1)" -eq '9' ]]; then
    CENTOS_NINE='9'
    EUROLINUX_NINE='9'
  fi
fi

if [[ -z "$CENTOS_SEVEN" && -z "$CENTOS_EIGHT" ]] || [[ "$CENTOS_SEVEN" != '7' && "$CENTOS_EIGHT" != '8' ]]; then
  echo "CentOS 7.x and 8.x Only"
  exit
fi

if [ ! -d "$DIR_TMP" ]; then
  echo "Centmin Mod LEMP Stack Required"
  exit
fi

# required otherwise fail2ban doesn't start
if [ ! -f /var/log/nginx/localhost_ssl.access.log ]; then
    touch /var/log/nginx/localhost_ssl.access.log
fi

# required otherwise fail2ban doesn't start
if [ ! -f /var/log/auth.log ]; then
    touch /var/log/auth.log
fi

######################################################

status() {
    GETJAILS=$(fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g')
    for j in $GETJAILS; do
    echo "---------------------------------------"
    MAXRETRY=$(fail2ban-client get $j maxretry)
    FINDTIME=$(fail2ban-client get $j findtime)
    BANTIME=$(fail2ban-client get $j bantime)
    if [ -f "/etc/fail2ban/filter.d/$j.local" ]; then
        LASTMOD=$(date -d @$(stat -c %Y /etc/fail2ban/filter.d/$j.local))
    else
        LASTMOD=$(date -d @$(stat -c %Y /etc/fail2ban/filter.d/$j.conf))
    fi
    if [[ "$MAXRETRY" -eq '1' && "$FINDTIME" -eq '1' ]]; then
        ALLOWRATE=1
    else
        if [[ "$MAXRETRY" -eq '1' ]]; then
            ALLOWMAX=1
        else
            ALLOWMAX=$(($MAXRETRY-1))
        fi
        ALLOWRATE=$(((86400/$FINDTIME) * $ALLOWMAX))
    fi
    echo "$j parameters: "
    echo -n "maxretry: $MAXRETRY "
    echo -n "findtime: $FINDTIME "
    echo "bantime: $BANTIME"
    echo "allow rate: $ALLOWRATE hits/day"
    echo "filter last modified: $LASTMOD"
    fail2ban-client status $j
    done
    echo "---------------------------------------"
    echo "All Time: Top 10 Banned IP Addresses:"
    if [[ "$(ls -lah /var/log | grep -q "fail2ban.log-$(date "+%Y")"; echo $?)" -eq '0' ]]; then
        zgrep -h "] Ban " /var/log/fail2ban.log{-*,*} | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    else
        zgrep -h "] Ban " /var/log/fail2ban.log | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    fi
    echo "---------------------------------------"
    echo "All Time: Top 10 Restored Banned IP Addresses:"
    if [[ "$(ls -lah /var/log | grep -q "fail2ban.log-$(date "+%Y")"; echo $?)" -eq '0' ]]; then
        zgrep -h "Restore Ban " /var/log/fail2ban.log{-*,*} | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    else
        zgrep -h "Restore Ban " /var/log/fail2ban.log | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    fi
    echo "---------------------------------------"
    echo "Yesterday: Top 10 Banned IP Addresses:"
    if [[ "$(ls -lah /var/log | grep -q "fail2ban.log-$(date "+%Y")"; echo $?)" -eq '0' ]]; then
        zgrep -h "] Ban " /var/log/fail2ban.log{-*,*} | grep `date -d "1 day ago" +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    else
        zgrep -h "] Ban " /var/log/fail2ban.log | grep `date -d "1 day ago" +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    fi
    echo "---------------------------------------"
    echo "Yesterday: Top 10 Restored Banned IP Addresses:"
    if [[ "$(ls -lah /var/log | grep -q "fail2ban.log-$(date "+%Y")"; echo $?)" -eq '0' ]]; then
        zgrep -h "Restore Ban " /var/log/fail2ban.log{-*,*} | grep `date -d "1 day ago" +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    else
        zgrep -h "Restore Ban " /var/log/fail2ban.log | grep `date -d "1 day ago" +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    fi
    echo "---------------------------------------"
    echo "Today: Top 10 Banned IP Addresses:"
    if [[ "$(ls -lah /var/log | grep -q "fail2ban.log-$(date "+%Y")"; echo $?)" -eq '0' ]]; then
        zgrep -h "] Ban " /var/log/fail2ban.log{-*,*} | grep `date +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    else
        zgrep -h "] Ban " /var/log/fail2ban.log | grep `date +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    fi
    echo "---------------------------------------"
    echo "Today: Top 10 Restored Banned IP Addresses:"
    if [[ "$(ls -lah /var/log | grep -q "fail2ban.log-$(date "+%Y")"; echo $?)" -eq '0' ]]; then
        zgrep -h "Restore Ban " /var/log/fail2ban.log{-*,*} | grep `date +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    else
        zgrep -h "Restore Ban " /var/log/fail2ban.log | grep `date +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    fi
    echo "---------------------------------------"
    echo "1 hr ago: Top 10 Banned IP Addresses:"
    if [[ "$(ls -lah /var/log | grep -q "fail2ban.log-$(date "+%Y")"; echo $?)" -eq '0' ]]; then
        zgrep -h "] Ban " /var/log/fail2ban.log{-*,*} | grep "$(date -d "1 hour ago" '+%Y-%m-%d %H:')" | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    else
        zgrep -h "] Ban " /var/log/fail2ban.log | grep "$(date -d "1 hour ago" '+%Y-%m-%d %H:')" | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    fi
    echo "---------------------------------------"
    echo "1 hr ago: Top 10 Restored Banned IP Addresses:"
    if [[ "$(ls -lah /var/log | grep -q "fail2ban.log-$(date "+%Y")"; echo $?)" -eq '0' ]]; then
        zgrep -h "Restore Ban " /var/log/fail2ban.log{-*,*} | grep "$(date -d "1 hour ago" '+%Y-%m-%d %H:')" | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    else
        zgrep -h "Restore Ban " /var/log/fail2ban.log | grep "$(date -d "1 hour ago" '+%Y-%m-%d %H:')" | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    fi
    echo "---------------------------------------"
}
pipinstall() {
  if [ "$CENTOS_SEVEN" == '7' ]; then
    if [ ! -f /usr/bin/pip3 ]; then
      yum -q -y install python3 python3-pip
      pip3 install --upgrade pip
    fi
    if ! rpm -q python3-setuptools >/dev/null 2>&1; then
      yum -q -y install python3-setuptools
    fi
  elif [ "$CENTOS_EIGHT" == '8' ]; then
    if [ ! -f /usr/bin/pip3 ]; then
      yum -q -y install python36 python3-pip
      pip3 install --upgrade pip
    fi
    if ! rpm -q python3-setuptools >/dev/null 2>&1; then
      yum -q -y install python3-setuptools
    fi
  else
    echo "Only CentOS 7.x and 8.x are supported."
    exit
  fi
}

install() {
    echo "---------------------------------------"
    echo "install fail2ban $FAILBAN_VER"
    echo "---------------------------------------"
    echo
    cd "$DIR_TMP"
    pipinstall
    pip3 install pyinotify
    git clone https://github.com/fail2ban/fail2ban
    cd fail2ban
    git fetch --tags
    git checkout ${FAIL2BAN_TAG}
    python3 setup.py install
    if [[ "$CENTOS_SEVEN" = '7' || "$CENTOS_EIGHT" = '8' ]]; then
        \cp -f build/fail2ban.service /usr/lib/systemd/system/fail2ban.service
        \cp -f files/fail2ban-tmpfiles.conf /usr/lib/tmpfiles.d/fail2ban.conf
        \cp -f files/fail2ban-logrotate /etc/logrotate.d/fail2ban
    else
        \cp -f files/redhat-initd /etc/init.d/fail2ban
    fi

    rm -rf /etc/fail2ban/action.d/cloudflare.conf
    wget -4 -cnv -O /etc/fail2ban/action.d/cloudflare.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/action.d/cloudflare.conf
    chmod 0640 /etc/fail2ban/action.d/cloudflare.conf

    rm -rf /etc/fail2ban/action.d/csfdeny.conf
    wget -4 -cnv -O /etc/fail2ban/action.d/csfdeny.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/action.d/csfdeny.conf

    rm -rf /etc/fail2ban/filter.d/http-xensec-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/http-xensec-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/http-xensec-main.conf    
    rm -rf /etc/fail2ban/filter.d/http-xensec.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/http-xensec.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/http-xensec.conf
    rm -rf /etc/fail2ban/filter.d/nginx-auth-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-auth-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-auth-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-auth.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-auth.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-auth.conf
    rm -rf /etc/fail2ban/filter.d/nginx-common-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-common-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-common-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-common.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-common.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-common.conf

    rm -rf /etc/fail2ban/filter.d/nginx-log4j-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-log4j-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-log4j-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-log4j.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-log4j.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-log4j.conf

    rm -rf /etc/fail2ban/filter.d/nginx-401-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-401-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-401-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-401.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-401.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-401.conf
    rm -rf /etc/fail2ban/filter.d/nginx-403-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-403-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-403-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-403.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-403.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-403.conf
    rm -rf /etc/fail2ban/filter.d/nginx-404-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-404-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-404-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-404.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-404.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-404.conf
    rm -rf /etc/fail2ban/filter.d/nginx-badrequests-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-badrequests-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-badrequests-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-badrequests.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-badrequests.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-badrequests.conf
    rm -rf /etc/fail2ban/filter.d/nginx-botsearch-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-botsearch-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-botsearch-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-botsearch.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-botsearch.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-botsearch.conf
    rm -rf /etc/fail2ban/filter.d/nginx-conn-limit-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-conn-limit-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-conn-limit-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-conn-limit.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-conn-limit.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-conn-limit.conf
    rm -rf /etc/fail2ban/filter.d/nginx-get-f5-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-get-f5-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-get-f5-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-get-f5.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-get-f5.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-get-f5.conf
    rm -rf /etc/fail2ban/filter.d/nginx-req-limit-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-req-limit-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-req-limit-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-req-limit.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-req-limit.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-req-limit.conf
    rm -rf /etc/fail2ban/filter.d/nginx-req-limit-repeat.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-req-limit-repeat.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-req-limit-repeat.conf
    rm -rf /etc/fail2ban/filter.d/nginx-w00tw00t-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-w00tw00t-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-w00tw00t-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-w00tw00t.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-w00tw00t.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-w00tw00t.conf
    rm -rf /etc/fail2ban/filter.d/nginx-xmlrpc-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-xmlrpc-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-xmlrpc-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-xmlrpc.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nginx-xmlrpc.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-xmlrpc.conf
    rm -rf /etc/fail2ban/filter.d/nsd.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/nsd.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nsd.conf
    rm -rf /etc/fail2ban/filter.d/pure-ftpd.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/pure-ftpd.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/pure-ftpd.conf
    rm -rf /etc/fail2ban/filter.d/vbulletin-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/vbulletin-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/vbulletin-main.conf
    rm -rf /etc/fail2ban/filter.d/vbulletin.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/vbulletin.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/vbulletin.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-auth-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/wordpress-auth-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-auth-main.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-auth.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/wordpress-auth.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-auth.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-comment-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/wordpress-comment-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-comment-main.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-comment.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/wordpress-comment.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-comment.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-pingback-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/wordpress-pingback-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-pingback-main.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-pingback.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/wordpress-pingback.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-pingback.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-pingback-repeat.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/wordpress-pingback-repeat.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-pingback-repeat.conf
    rm -rf /etc/fail2ban/filter.d/phpmyadmin-cmm.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/phpmyadmin-cmm.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/phpmyadmin-cmm.conf
    rm -rf /etc/fail2ban/filter.d/phpmyadmin-other.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/phpmyadmin-other.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/phpmyadmin-other.conf
    rm -rf /etc/fail2ban/filter.d/joomla-auth-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/joomla-auth-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/joomla-auth-main.conf
    rm -rf /etc/fail2ban/filter.d/joomla-auth.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/joomla-auth.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/joomla-auth.conf
    rm -rf /etc/fail2ban/filter.d/magento-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/magento-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/magento-main.conf
    rm -rf /etc/fail2ban/filter.d/magento.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/magento.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/magento.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-fail2ban-plugin.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/wordpress-fail2ban-plugin.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-fail2ban-plugin.conf
    rm -rf /etc/fail2ban/filter.d/shells-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/shells-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/shells-main.conf
    rm -rf /etc/fail2ban/filter.d/shells.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/shells.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/shells.conf
    rm -rf /etc/fail2ban/filter.d/adminer-main.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/adminer-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/adminer-main.conf
    rm -rf /etc/fail2ban/filter.d/adminer.conf
    wget -4 -cnv -O /etc/fail2ban/filter.d/adminer.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/adminer.conf
    
    echo "[DEFAULT]" > /etc/fail2ban/jail.local
    echo "ignoreip = 127.0.0.1/8 ::1 $USERIP $SERVERIPS" >> /etc/fail2ban/jail.local
    wget -4 -cnv -O /etc/fail2ban/jail.local.download https://github.com/centminmod/centminmod-fail2ban/raw/master/jail.local
    sed -i '/\[DEFAULT\]/d' /etc/fail2ban/jail.local.download
    sed -i '/ignoreip/d' /etc/fail2ban/jail.local.download
    cat /etc/fail2ban/jail.local.download >> /etc/fail2ban/jail.local
    rm -rf /etc/fail2ban/jail.local.download

    if [ ! -f /var/log/fail2ban.log ]; then
        touch /var/log/fail2ban.log
    fi

    if [[ "$CENTOS_SEVEN" = '7' || "$CENTOS_EIGHT" = '8' ]]; then
        systemctl daemon-reload
        systemctl stop fail2ban
        systemctl start fail2ban
        systemctl enable fail2ban
        echo
        systemctl status fail2ban
    else
        service fail2ban stop 
        service fail2ban start 
        chkconfig fail2ban on
        echo
        service fail2ban status 
    fi
    echo
    sleep 5
    fail2ban-client status
    echo
    echo "---------------------------------------"
    echo "fail2ban $FAILBAN_VER installed"
    echo "---------------------------------------"
    echo
}

case "$1" in
    install )
        install
        ;;
    status )
        status
        ;;
    * )
        echo "$0 {install|status}"
        ;;
esac