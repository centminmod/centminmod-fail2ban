# fail2ban for centminmod.com LEMP stacks

fail2ban 0.10+ setup for [centminmod.com LEMP stacks](https://centminmod.com) with [CSF Firewall](https://centminmod.com/csf_firewall.html). CentOS EPEL Yum repo fail2ban version is using older fail2ban 0.9.6+, while below instructions are for fail2ban 0.10+ which now supports IPv6 addresses and improved performance. Suggestions, corrections and bug fixes are welcomed

* https://github.com/fail2ban/fail2ban
* https://github.com/fail2ban/fail2ban/wiki/Proper-fail2ban-configuration
* https://github.com/fail2ban/fail2ban/wiki/Troubleshooting
* [fail2ban 0.10 change log](https://github.com/fail2ban/fail2ban/blob/0.10/ChangeLog)

## fail2ban installation for CentOS 7.x Only

    USERIP=$(last -i | grep "still logged in" | awk '{print $3}' | uniq)
    SERVERIPS=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
    IGNOREIP=$(echo "ignoreip = 127.0.0.1/8 ::1 $USERIP $SERVERIPS")
    cd /svr-setup/
    git clone -b 0.10 https://github.com/fail2ban/fail2ban
    cd fail2ban
    python setup.py install
    cp /svr-setup/fail2ban/files/fail2ban.service /usr/lib/systemd/system/fail2ban.service
    cp /svr-setup/fail2ban/files/fail2ban-tmpfiles.conf /usr/lib/tmpfiles.d/fail2ban.conf
    cp /svr-setup/fail2ban/files/fail2ban-logrotate /etc/logrotate.d/fail2ban
    echo "[DEFAULT]" > /etc/fail2ban/jail.local
    echo "ignoreip = 127.0.0.1/8 ::1 $USERIP $SERVERIPS" >> /etc/fail2ban/jail.local
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
* centmin mod buffers access log writes to Nginx in memory with directives `main_ext buffer=256k flush=60m` and custom log format called `main_ext`, so for fail2ban to work optimally, you would need to disable access log memory buffering and revert to nginx default log format by removing those three directives from your Nginx vhost config file's `access_log` line. So `access_log /home/nginx/domains/domain.com/log/access.log main_ext buffer=256k flush=60m;` becomes `access_log /home/nginx/domains/domain.com/log/access.log;` and restart Nginx
* if switching from CSF Firewall to Cloudflare API action from `action.d/cloudflare.conf`, ensure Centmin Mod 123.09beta01 branch Nginx vhosts are setup with proper real IP detection and Cloudflare IP whitelisting. You can use [tools/csfcf.sh](https://community.centminmod.com/threads/csfcf-sh-automate-cloudflare-nginx-csf-firewall-setups.6241/) script to automate the Cloudflare Nginx configuration and Cloudflare IP whitelisting management outlined [here](https://community.centminmod.com/threads/csfcf-sh-automate-cloudflare-nginx-csf-firewall-setups.6241/). You can setup a cronjob to run the script in auto mode `/usr/local/src/centminmod/tools/csfcf.sh auto`.This ensures visitor's real IP address is passed on in your server logs which fail2ban reads.
* default `action.d/csfdeny.conf` ban option is to use `csf -d` to permanentaly block ip. Though temp block would be more appropriate:

```
-td, --tempdeny ip ttl [-p port] [-d direction] [comment]
       Add an IP to the temp IP ban list. ttl is how long to blocks for
       (default:seconds, can use one suffix of h/m/d).  Optional  port.
       Optional  direction  of  block  can  be one of: in, out or inout
       (default:in)
```

## examples

```
fail2ban-client status
Status
|- Number of jail:      13
`- Jail list:   nginx-auth, nginx-auth-main, nginx-botsearch, nginx-conn-limit, nginx-get-f5, nginx-req-limit, nginx-req-limit-main, nginx-w00tw00t, nginx-xmlrpc, vbulletin, wordpress-auth, wordpress-comment, wordpress-pingback
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

testing Centmin Mod's `centmin.sh menu option 22` auto installed and configured Wordpress Nginx vhost which auto configures nginx level rate limiting on wp-login.php pages. Connection limit is disabled by default but can be enabled.

`/usr/local/nginx/conf/nginx.conf` level

    limit_req_zone $binary_remote_addr zone=xwplogin:16m rate=40r/m;
    #limit_conn_zone $binary_remote_addr zone=xwpconlimit:16m;

vhost level `/usr/local/nginx/conf/conf.d/domain.com.conf`

    location ~* /(wp-login\.php) {
        limit_req zone=xwplogin burst=1 nodelay;
        #limit_conn xwpconlimit 30;

use Siege benchmark tool (auto installed with Centmin Mod LEMP stacks) connection timed out entries are when CSF Firewall banned the IP via `csfdeny.conf` action profile:

```
siege -b -c3 -r10 http://domain.com/wp-login.php
** SIEGE 4.0.2
** Preparing 3 concurrent users for battle.
The server is now under siege...
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.57 secs:    7066 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.62 secs:    7066 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.94 secs:  100250 bytes ==> GET  /wp-admin/load-styles.php?c=0&dir=ltr&load%5B%5D=dashicons,buttons,forms,l10n,login&ver=4.7.4
HTTP/1.1 200     0.93 secs:  100250 bytes ==> GET  /wp-admin/load-styles.php?c=0&dir=ltr&load%5B%5D=dashicons,buttons,forms,l10n,login&ver=4.7.4
HTTP/1.1 503     0.61 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.45 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.49 secs:    7066 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.44 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.94 secs:  100250 bytes ==> GET  /wp-admin/load-styles.php?c=0&dir=ltr&load%5B%5D=dashicons,buttons,forms,l10n,login&ver=4.7.4
HTTP/1.1 503     0.56 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.51 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.46 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.46 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.50 secs:    7066 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.47 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 200     0.91 secs:  100250 bytes ==> GET  /wp-admin/load-styles.php?c=0&dir=ltr&load%5B%5D=dashicons,buttons,forms,l10n,login&ver=4.7.4
HTTP/1.1 503     0.48 secs:    1665 bytes ==> GET  /wp-login.php
HTTP/1.1 503     0.48 secs:    1665 bytes ==> GET  /wp-login.php
[error] socket: -1555597568 connection timed out.: Connection timed out
[error] socket: -1538812160 connection timed out.: Connection timed out
[error] socket: -1538812160 connection timed out.: Connection timed out
[error] socket: -1555597568 connection timed out.: Connection timed out
[error] socket: -1555597568 connection timed out.: Connection timed out
[error] socket: -1538812160 connection timed out.: Connection timed out
[error] socket: -1555597568 connection timed out.: Connection timed out
[error] socket: -1538812160 connection timed out.: Connection timed out

Transactions:                      8 hits
Availability:                  23.53 %
Elapsed time:                  64.99 secs
Data transferred:               0.44 MB
Response time:                  1.82 secs
Transaction rate:               0.12 trans/sec
Throughput:                     0.01 MB/sec
Concurrency:                    0.22
Successful transactions:           8
Failed transactions:              26
Longest transaction:            0.94
Shortest transaction:           0.44
```

Centmin Mod Nginx error log entries at `/home/nginx/domains/domain.com/log/error.log`

    tail -3 error.log                                                  
    2017/05/12 06:32:07 [error] 30167#30167: *104 limiting requests, excess: 1.068 by zone "xwplogin", client: IPADDR, server: domain.com, request: "GET /wp-login.php HTTP/1.1", host: "domain.com"
    2017/05/12 06:32:07 [error] 30167#30167: *105 limiting requests, excess: 1.001 by zone "xwplogin", client: IPADDR, server: domain.com, request: "GET /wp-login.php HTTP/1.1", host: "domain.com"
    2017/05/12 06:32:07 [error] 30167#30167: *108 limiting requests, excess: 1.735 by zone "xwplogin", client: IPADDR, server: domain.com, request: "GET /wp-login.php HTTP/1.1", host: "domain.com"

CSF Firewall blocked IP note the `Added by Fail2Ban for nginx-req-limit` comment in csf.deny entry

    csf -g IPADDR                                                
    
    Chain            num   pkts bytes target     prot opt in     out     source               destination         
    No matches found for IPADDR in iptables
    
    
    IPSET: Set:chain_DENY Match:IPADDR Setting: File:/etc/csf/csf.deny
    
    csf.deny: IPADDR # Added by Fail2Ban for nginx-req-limit - Fri May 12 07:09:21 2017

nginx-req-limit filter status and regex test

```
fail2ban-client status nginx-req-limit                       
Status for the jail: nginx-req-limit
|- Filter
|  |- Currently failed: 1
|  |- Total failed:     21
|  `- File list:        /home/nginx/domains/domain.com/log/error.log /home/nginx/domains/demodomain.com/log/error.log
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   IPADDR
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

Failregex: 21 total
|-  #) [# of hits] regular expression
|   1) [21] ^\s*\[error\] \d+#\d+: \*\d+ limiting requests, excess: [\d\.]+ by zone "(?:[^"]+)", client: <HOST>,
`-

Ignoreregex: 0 total

Date template hits:
|- [# of hits] date format
|  [21] {^LN-BEG}ExYear(?P<_sep>[-/.])Month(?P=_sep)Day[T ]24hour:Minute:Second(?:[.,]Microseconds)?(?:\s*Zone offset)?
`-

Lines: 21 lines, 0 ignored, 21 matched, 0 missed
[processed in 0.01 sec]

```

Unbanning the IP via fail2ban-client

    fail2ban-client unban IPADDR



