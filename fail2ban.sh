#!/bin/bash
######################################################
# written by George Liu (eva2000) centminmod.com
# https://github.com/centminmod/centminmod-fail2ban
######################################################
# variables
#############
DT=`date +"%d%m%y-%H%M%S"`
FAILBAN_VER='0.10'

USERIP=$(last -i | grep "still logged in" | awk '{print $3}' | uniq)
SERVERIPS=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
IGNOREIP=$(echo "ignoreip = 127.0.0.1/8 ::1 $USERIP $SERVERIPS")
DIR_TMP='/svr-setup'
######################################################
# functions
#############
CENTOSVER=$(awk '{ print $3 }' /etc/redhat-release)

if [ "$CENTOSVER" == 'release' ]; then
    CENTOSVER=$(awk '{ print $4 }' /etc/redhat-release | cut -d . -f1,2)
    if [[ "$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
    fi
fi

if [[ "$(cat /etc/redhat-release | awk '{ print $3 }' | cut -d . -f1)" = '6' ]]; then
    CENTOS_SIX='6'
fi

if [ "$CENTOSVER" == 'Enterprise' ]; then
    CENTOSVER=$(cat /etc/redhat-release | awk '{ print $7 }')
    OLS='y'
fi

if [[ -f /etc/system-release && "$(awk '{print $1,$2,$3}' /etc/system-release)" = 'Amazon Linux AMI' ]]; then
    CENTOS_SIX='6'
fi

if [[ "$CENTOS_SEVEN" != '7' ]]; then
  echo "CentOS 7.x Only"
  exit
fi

if [ ! -d "$DIR_TMP" ]; then
  echo "Centmin Mod LEMP Stack Required"
  exit
fi

######################################################

status() {
    GETJAILS=$(fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g')
    for j in $GETJAILS; do
    echo "---------------------------------------"
    fail2ban-client status $j
    done
    echo "---------------------------------------"
    echo "All Time: Top 10 Banned IP Addresses:"
    zgrep -h "] Ban " /var/log/fail2ban.log* | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    echo "---------------------------------------"
    echo "All Time: Top 10 Restored Banned IP Addresses:"
    zgrep -h "Restore Ban " /var/log/fail2ban.log* | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    echo "---------------------------------------"
    echo "Yesterday: Top 10 Banned IP Addresses:"
    zgrep -h "] Ban " /var/log/fail2ban.log* | grep `date -d "1 day ago" +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    echo "---------------------------------------"
    echo "Yesterday: Top 10 Restored Banned IP Addresses:"
    zgrep -h "Restore Ban " /var/log/fail2ban.log* | grep `date -d "1 day ago" +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    echo "---------------------------------------"
    echo "Today: Top 10 Banned IP Addresses:"
    zgrep -h "] Ban " /var/log/fail2ban.log* | grep `date +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    echo "---------------------------------------"
    echo "Today: Top 10 Restored Banned IP Addresses:"
    zgrep -h "Restore Ban " /var/log/fail2ban.log* | grep `date +%Y-%m-%d` | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    echo "---------------------------------------"
    echo "1 hr ago: Top 10 Banned IP Addresses:"
    zgrep -h "] Ban " /var/log/fail2ban.log* | grep "$(date -d "1 hour ago" '+%Y-%m-%d %H:')" | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    echo "---------------------------------------"
    echo "1 hr ago: Top 10 Restored Banned IP Addresses:"
    zgrep -h "Restore Ban " /var/log/fail2ban.log* | grep "$(date -d "1 hour ago" '+%Y-%m-%d %H:')" | awk '{print $NF, $6}' | sort | uniq -c | sort -rn | tail -10
    echo "---------------------------------------"
}

pipinstall() {
if [ ! -f /usr/bin/pip ]; then
  yum -q -y install python2-pip
  pip install --upgrade pip
fi
}

install() {
    echo "---------------------------------------"
    echo "install fail2ban $FAILBAN_VER"
    echo "---------------------------------------"
    echo
    cd "$DIR_TMP"
    pipinstall
    pip install pyinotify
    git clone -b ${FAILBAN_VER} https://github.com/fail2ban/fail2ban
    cd fail2ban
    python setup.py install
    \cp -f /svr-setup/fail2ban/files/fail2ban.service /usr/lib/systemd/system/fail2ban.service
    \cp -f /svr-setup/fail2ban/files/fail2ban-tmpfiles.conf /usr/lib/tmpfiles.d/fail2ban.conf
    \cp -f /svr-setup/fail2ban/files/fail2ban-logrotate /etc/logrotate.d/fail2ban

    rm -rf /etc/fail2ban/action.d/cloudflare.conf
    wget -cnv -O /etc/fail2ban/action.d/cloudflare.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/action.d/cloudflare.conf
    chmod 0640 /etc/fail2ban/action.d/cloudflare.conf

    rm -rf /etc/fail2ban/action.d/csfdeny.conf
    wget -cnv -O /etc/fail2ban/action.d/csfdeny.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/action.d/csfdeny.conf
    
    rm -rf /etc/fail2ban/filter.d/http-xensec.conf
    wget -cnv -O /etc/fail2ban/filter.d/http-xensec.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/http-xensec.conf
    rm -rf /etc/fail2ban/filter.d/nginx-auth-main.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-auth-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-auth-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-auth.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-auth.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-auth.conf
    rm -rf /etc/fail2ban/filter.d/nginx-401.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-401.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-401.conf
    rm -rf /etc/fail2ban/filter.d/nginx-403.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-403.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-403.conf
    rm -rf /etc/fail2ban/filter.d/nginx-404.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-404.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-404.conf
    rm -rf /etc/fail2ban/filter.d/nginx-badrequests.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-badrequests.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-badrequests.conf
    rm -rf /etc/fail2ban/filter.d/nginx-botsearch.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-botsearch.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-botsearch.conf
    rm -rf /etc/fail2ban/filter.d/nginx-conn-limit.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-conn-limit.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-conn-limit.conf
    rm -rf /etc/fail2ban/filter.d/nginx-get-f5.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-get-f5.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-get-f5.conf
    rm -rf /etc/fail2ban/filter.d/nginx-req-limit-main.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-req-limit-main.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-req-limit-main.conf
    rm -rf /etc/fail2ban/filter.d/nginx-req-limit.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-req-limit.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-req-limit.conf
    rm -rf /etc/fail2ban/filter.d/nginx-req-limit-repeat.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-req-limit-repeat.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-req-limit-repeat.conf
    rm -rf /etc/fail2ban/filter.d/nginx-w00tw00t.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-w00tw00t.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-w00tw00t.conf
    rm -rf /etc/fail2ban/filter.d/nginx-xmlrpc.conf
    wget -cnv -O /etc/fail2ban/filter.d/nginx-xmlrpc.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nginx-xmlrpc.conf
    rm -rf /etc/fail2ban/filter.d/nsd.conf
    wget -cnv -O /etc/fail2ban/filter.d/nsd.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/nsd.conf
    rm -rf /etc/fail2ban/filter.d/pure-ftpd.conf
    wget -cnv -O /etc/fail2ban/filter.d/pure-ftpd.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/pure-ftpd.conf
    rm -rf /etc/fail2ban/filter.d/vbulletin.conf
    wget -cnv -O /etc/fail2ban/filter.d/vbulletin.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/vbulletin.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-auth.conf
    wget -cnv -O /etc/fail2ban/filter.d/wordpress-auth.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-auth.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-comment.conf
    wget -cnv -O /etc/fail2ban/filter.d/wordpress-comment.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-comment.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-pingback.conf
    wget -cnv -O /etc/fail2ban/filter.d/wordpress-pingback.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-pingback.conf
    rm -rf /etc/fail2ban/filter.d/wordpress-pingback-repeat.conf
    wget -cnv -O /etc/fail2ban/filter.d/wordpress-pingback-repeat.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/wordpress-pingback-repeat.conf
    rm -rf /etc/fail2ban/filter.d/phpmyadmin-cmm.conf
    wget -cnv -O /etc/fail2ban/filter.d/phpmyadmin-cmm.conf https://github.com/centminmod/centminmod-fail2ban/raw/master/filter.d/phpmyadmin-cmm.conf
    
    echo "[DEFAULT]" > /etc/fail2ban/jail.local
    echo "ignoreip = 127.0.0.1/8 ::1 $USERIP $SERVERIPS" >> /etc/fail2ban/jail.local
    wget -cnv -O /etc/fail2ban/jail.local.download https://github.com/centminmod/centminmod-fail2ban/raw/master/jail.local
    sed -i '/\[DEFAULT\]/d' /etc/fail2ban/jail.local.download
    sed -i '/ignoreip/d' /etc/fail2ban/jail.local.download
    cat /etc/fail2ban/jail.local.download >> /etc/fail2ban/jail.local
    rm -rf /etc/fail2ban/jail.local.download

    systemctl daemon-reload
    systemctl restart fail2ban
    systemctl enable fail2ban
    echo
    systemctl status fail2ban
    echo
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