# fail2ban for centminmod.com LEMP stacks

fail2ban setup for [centminmod.com LEMP stacks](https://centminmod.com) with CSF Firewall

* https://github.com/fail2ban/fail2ban
* https://github.com/fail2ban/fail2ban/wiki/Proper-fail2ban-configuration
* https://github.com/fail2ban/fail2ban/wiki/Troubleshooting

## fail2ban installation for CentOS 7.x Only

    USERIP=$(last -i | grep "still logged in" | awk '{print $3}')
    SERVERIPS=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
    IGNOREIP=$(echo "ignoreip = 127.0.0.1/8 ::1 $USERIP $SERVERIPS")
    cd /svr-setup/
    git clone -b 0.10 https://github.com/fail2ban/fail2ban
    python setup.py install
    cp /svr-setup/fail2ban/files/fail2ban.service /usr/lib/systemd/system/fail2ban.service
    cp /svr-setup/fail2ban/files/fail2ban-tmpfiles.conf /usr/lib/tmpfiles.d/fail2ban.conf
    cp /svr-setup/fail2ban/files/fail2ban-logrotate /etc/logrotate.d/fail2ban
    echo "ignoreip = 127.0.0.1/8 ::1 $USERIP $SERVERIPS" > /etc/fail2ban/jail.local
    systemctl daemon-reload
    systemctl start fail2ban
    systemctl enable fail2ban
    systemctl status fail2ban

Then 

* populate your `/etc/fail2ban/jail.local` with the [jail.local](/jail.local) contents
* copy [action.d](/action.d) files to `/etc/fail2ban/action.d`
* copy [filter.d](/filter.d) files to `/etc/fail2ban/filter.d`
* restart fail2ban `systemctl restart fail2ban` or `fail2ban-client reload`

## notes

* currently this configuration is a work in progress, so not fully tested. Use at your own risk
* centmin mod buffers access log writes to Nginx in memory with directives `buffer=256k flush=60m`, so for fail2ban to work optimally, you would need to disable access log memory buffering by removing those two directives from your Nginx vhost config file's `access_log` line. ```access_log /home/nginx/domains/domain.com/log/access.log main_ext buffer=256k flush=60m;```
* suggestions, corrections and bug fixes are welcomed
