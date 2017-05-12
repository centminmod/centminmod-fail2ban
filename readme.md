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
* centmin mod buffers access log writes to Nginx in memory with directives `main_ext buffer=256k flush=60m` and custom log format called `main_ext`, so for fail2ban to work optimally, you would need to disable access log memory buffering and reverting to nginx default log format by removing those three directives from your Nginx vhost config file's `access_log` line. So `access_log /home/nginx/domains/domain.com/log/access.log main_ext buffer=256k flush=60m;` becomes `access_log /home/nginx/domains/domain.com/log/access.log;` and restart Nginx
* suggestions, corrections and bug fixes are welcomed

## examples

```
fail2ban-client status
Status
|- Number of jail:      13
`- Jail list:   nginx-auth, nginx-auth-main, nginx-botsearch, nginx-get-f5, nginx-req-limit, nginx-req-limit-main, nginx-w00tw00t, nginx-xmlrpc, vbulletin, wordpress-auth, wordpress-comment, wordpress-dict, wordpress-pingback
```

wordpress-auth filter status

```
fail2ban-client status wordpress-auth                 
Status for the jail: wordpress-auth
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/demodomain.com/log/access.log /home/nginx/domains/domain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

testing Centmin Mod's centmin.sh menu option 22 auto installed and configured Wordpress Nginx vhost which auto configures nginx level rate limiting on wp-login.php pages

use Siege benchmark tool (auto installed with Centmin Mod LEMP stacks):

```
siege -b -c2 -r3 http://domain.com/wp-login.php
** SIEGE 4.0.2
** Preparing 2 concurrent users for battle.
The server is now under siege...
HTTP/1.1 200     0.52 secs:    7066 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.54 secs:    7066 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.93 secs:  100250 bytes ==> GET  /wp-admin/load-styles.php?c=0&dir=ltr&load%5B%5D=dashicons,buttons,forms,l10n,login&ver=4.7.4
HTTP/1.1 200     0.93 secs:  100250 bytes ==> GET  /wp-admin/load-styles.php?c=0&dir=ltr&load%5B%5D=dashicons,buttons,forms,l10n,login&ver=4.7.4
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.51 secs:    7066 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.90 secs:  100250 bytes ==> GET  /wp-admin/load-styles.php?c=0&dir=ltr&load%5B%5D=dashicons,buttons,forms,l10n,login&ver=4.7.4

Transactions:                      6 hits
Availability:                  66.67 %
Elapsed time:                   3.33 secs
Data transferred:               0.31 MB
Response time:                  0.96 secs
Transaction rate:               1.80 trans/sec
Throughput:                     0.09 MB/sec
Concurrency:                    1.72
Successful transactions:           6
Failed transactions:               3
Longest transaction:            0.93
Shortest transaction:           0.47
```

nginx-req-limit filter status and regex test

```
fail2ban-client status nginx-req-limit
Status for the jail: nginx-req-limit
|- Filter
|  |- Currently failed: 1
|  |- Total failed:     3
|  `- File list:        /home/nginx/domains/domain.com/log/error.log /home/nginx/domains/demodomain.com/log/error.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

```
fail2ban-regex error.log /etc/fail2ban/filter.d/nginx-req-limit.conf 

Running tests
=============

Use   failregex filter file : nginx-req-limit, basedir: /etc/fail2ban
Use      datepattern : Default Detectors
Use         log file : error.log
Use         encoding : UTF-8


Results
=======

Failregex: 3 total
|-  #) [# of hits] regular expression
|   1) [3] ^\s*\[error\] \d+#\d+: \*\d+ limiting requests, excess: [\d\.]+ by zone "(?:[^"]+)", client: <HOST>,
`-

Ignoreregex: 0 total

Date template hits:
|- [# of hits] date format
|  [3] {^LN-BEG}ExYear(?P<_sep>[-/.])Month(?P=_sep)Day[T ]24hour:Minute:Second(?:[.,]Microseconds)?(?:\s*Zone offset)?
`-

Lines: 3 lines, 0 ignored, 3 matched, 0 missed
```


