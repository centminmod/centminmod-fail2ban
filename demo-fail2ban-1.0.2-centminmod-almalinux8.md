Centmin Mod LEMP stack [fail2ban 1.0.2 implementation test on AlmaLinux 8.7](https://github.com/centminmod/centminmod-fail2ban/tree/1.0).

```
cat /etc/centminmod-release 
130.00beta01.b280
```

```
cat /etc/os-release 
NAME="AlmaLinux"
VERSION="8.7 (Stone Smilodon)"
ID="almalinux"
ID_LIKE="rhel centos fedora"
VERSION_ID="8.7"
PLATFORM_ID="platform:el8"
PRETTY_NAME="AlmaLinux 8.7 (Stone Smilodon)"
ANSI_COLOR="0;34"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:almalinux:almalinux:8::baseos"
HOME_URL="https://almalinux.org/"
DOCUMENTATION_URL="https://wiki.almalinux.org/"
BUG_REPORT_URL="https://bugs.almalinux.org/"

ALMALINUX_MANTISBT_PROJECT="AlmaLinux-8"
ALMALINUX_MANTISBT_PROJECT_VERSION="8.7"
REDHAT_SUPPORT_PRODUCT="AlmaLinux"
REDHAT_SUPPORT_PRODUCT_VERSION="8.7"
```

```
fail2ban-server --version
Fail2Ban v1.0.2

python3 -c 'from fail2ban.version import version; print(version)'
1.0.2
```

```
pip3 show fail2ban

Name: fail2ban
Version: 1.0.2
Summary: Ban IPs that make too many password failures
Home-page: http://www.fail2ban.org
Author: Cyril Jaquier & Fail2Ban Contributors
Author-email: cyril.jaquier@fail2ban.org
License: GPL
Location: /usr/local/lib/python3.6/site-packages
Requires: 
```

```
csf -g 159.203.xxx.xxx

Table  Chain            num   pkts bytes target     prot opt in     out     source               destination         
No matches found for 159.203.xxx.xxx in iptables


IPSET: Set:chain_DENY Match:159.203.xxx.xxx Setting: File:/etc/csf/csf.deny


ip6tables:

Table  Chain            num   pkts bytes target     prot opt in     out     source               destination         
No matches found for 159.203.xxx.xxx in ip6tables

csf.deny: 159.203.xxx.xxx # Added by Fail2Ban for nginx-common-main - Fri Apr  7 00:41:33 2023
```

```
fail2ban-regex "/var/log/nginx/localhost.access.log" /etc/fail2ban/filter.d/nginx-common-main.conf --print-all-matched


Running tests
=============

Use   failregex filter file : nginx-common-main, basedir: /etc/fail2ban
Use         log file : /var/log/nginx/localhost.access.log
Use         encoding : UTF-8


Results
=======

Failregex: 1 total
|-  #) [# of hits] regular expression
|   2) [1] ^<HOST> - - .* \\x[\d+]..* 400 .*$
`-

Ignoreregex: 0 total

Date template hits:
|- [# of hits] date format
|  [43] Day(?P<_sep>[-/])MON(?P=_sep)ExYear[ :]?24hour:Minute:Second(?:\.Microseconds)?(?: Zone offset)?
`-

Lines: 43 lines, 0 ignored, 1 matched, 42 missed
[processed in 0.02 sec]

|- Matched line(s):
|  159.203.xxx.xxx - - [07/Apr/2023:00:41:32 -0400] "\x16\x03\x01\x00{\x01\x00\x00w\x03\x03\x88\x1A\x82\xC1\xE6\xA3\xD2\xB6pLp\x15\xD3\xE4\xF4\x7F`}\xDE\xBE\x10\xB4\x91\x9E\xED\xA3\xE0S\xD2v\x90 \x00\x00\x1A\xC0/\xC0+\xC0\x11\xC0\x07\xC0\x13\xC0\x09\xC0\x14\xC0" 400 150 "-" "-"
`-
Missed line(s): too many to print.  Use --print-all-missed to print all 42 lines
```

# fail2ban.sh

fail2ban has a native `fail2ban-client status` command that can list all fail2ban jailnames and `fail2ban-client status jailname` will output the status of a specific jailname. The `fail2ban.sh` script supports a similar feature just that the specific jailname's status output is in JSON format for easier parsing and scripting.

The native command output:

```
fail2ban-client status wordpress-pingback
Status for the jail: wordpress-pingback
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     3
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain3.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log /home/nginx/domains/domain4.com/log/access.log
`- Actions
   |- Currently banned: 2
   |- Total banned:     2
   `- Banned IP list:   162.158.244.169 162.158.244.165
```

Using `fail2ban.sh`:

```
./fail2ban.sh 
./fail2ban.sh install
./fail2ban.sh status
./fail2ban.sh get JAILNAME
```

Example getting the status for jailname = `wordpress-pingback`

```
./fail2ban.sh get wordpress-pingback
{
  "jail": "wordpress-pingback",
  "currentlyFailed": "0",
  "totalFailed": "3",
  "logPaths": ["/home/nginx/domains/domain.com/log/access.log", "/home/nginx/domains/log4j.domain.com/log/access.log", "/home/nginx/domains/domain3.com/log/access.log", "/home/nginx/domains/demodomain.com/log/access.log", "/home/nginx/domains/domain4.com/log/access.log"],
  "currentlyBanned": "2",
  "totalBanned": "2",
  "bannedIPList": ["162.158.244.169", "162.158.244.165"]
}
```

Using `jq` to parse `logPaths`

```
./fail2ban.sh get wordpress-pingback | jq -r '.logPaths[]'
/home/nginx/domains/domain.com/log/access.log
/home/nginx/domains/log4j.domain.com/log/access.log
/home/nginx/domains/domain3.com/log/access.log
/home/nginx/domains/demodomain.com/log/access.log
/home/nginx/domains/domain4.com/log/access.log
```

Using `jq` to parse `bannedIPList`

```
./fail2ban.sh get wordpress-pingback | jq -r '.bannedIPList[]'
162.158.244.169
162.158.244.165
```

## Jailnames

Currently, there are 28 fail2ban jailnames configured:

* nginx-auth
* nginx-auth-main
* nginx-badrequests
* nginx-badrequests-main
* nginx-botsearch
* nginx-botsearch-main
* nginx-common
* nginx-common-main
* nginx-conn-limit
* nginx-conn-limit-main
* nginx-log4j
* nginx-log4j-main
* nginx-req-limit
* nginx-req-limit-main
* nginx-xmlrpc
* nginx-xmlrpc-main
* shells
* shells-main
* vbulletin
* vbulletin-main
* wordpress-auth
* wordpress-auth-main
* wordpress-comment
* wordpress-comment-main
* wordpress-fail2ban-plugin
* wordpress-pingback
* wordpress-pingback-main
* wordpress-pingback-repeat

## status

```
./fail2ban.sh status

---------------------------------------
nginx-auth parameters: 
maxretry: 3 findtime: 600 bantime: 3600
allow rate: 288 hits/day
filter last modified: Thu Apr  6 16:58:42 EDT 2023
Status for the jail: nginx-auth
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-auth-main parameters: 
maxretry: 3 findtime: 600 bantime: 3600
allow rate: 288 hits/day
filter last modified: Thu Apr  6 16:58:42 EDT 2023
Status for the jail: nginx-auth-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.error.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-badrequests parameters: 
maxretry: 1 findtime: 600 bantime: 604800
allow rate: 144 hits/day
filter last modified: Thu Apr  6 16:58:48 EDT 2023
Status for the jail: nginx-badrequests
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-badrequests-main parameters: 
maxretry: 1 findtime: 600 bantime: 604800
allow rate: 144 hits/day
filter last modified: Thu Apr  6 16:58:47 EDT 2023
Status for the jail: nginx-badrequests-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-botsearch parameters: 
maxretry: 2 findtime: 600 bantime: 600
allow rate: 144 hits/day
filter last modified: Thu Apr  6 17:07:35 EDT 2023
Status for the jail: nginx-botsearch
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     1
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-botsearch-main parameters: 
maxretry: 2 findtime: 600 bantime: 600
allow rate: 144 hits/day
filter last modified: Thu Apr  6 16:58:48 EDT 2023
Status for the jail: nginx-botsearch-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-common parameters: 
maxretry: 1 findtime: 43200 bantime: 604800
allow rate: 2 hits/day
filter last modified: Thu Apr  6 16:58:43 EDT 2023
Status for the jail: nginx-common
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-common-main parameters: 
maxretry: 1 findtime: 43200 bantime: 604800
allow rate: 2 hits/day
filter last modified: Thu Apr  6 16:58:43 EDT 2023
Status for the jail: nginx-common-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     1
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   159.203.xxx.xxx
---------------------------------------
nginx-conn-limit parameters: 
maxretry: 5 findtime: 600 bantime: 7200
allow rate: 576 hits/day
filter last modified: Thu Apr  6 16:58:49 EDT 2023
Status for the jail: nginx-conn-limit
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/error.log /home/nginx/domains/log4j.domain.com/log/error.log /home/nginx/domains/domain2.com/log/error.log /home/nginx/domains/demodomain.com/log/error.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-conn-limit-main parameters: 
maxretry: 5 findtime: 600 bantime: 7200
allow rate: 576 hits/day
filter last modified: Thu Apr  6 16:58:49 EDT 2023
Status for the jail: nginx-conn-limit-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.error.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-log4j parameters: 
maxretry: 1 findtime: 86400 bantime: 86400
allow rate: 1 hits/day
filter last modified: Thu Apr  6 16:58:44 EDT 2023
Status for the jail: nginx-log4j
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     2
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   192.xxx.xxx.xxx
---------------------------------------
nginx-log4j-main parameters: 
maxretry: 1 findtime: 86400 bantime: 86400
allow rate: 1 hits/day
filter last modified: Thu Apr  6 16:58:43 EDT 2023
Status for the jail: nginx-log4j-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-req-limit parameters: 
maxretry: 5 findtime: 600 bantime: 7200
allow rate: 576 hits/day
filter last modified: Thu Apr  6 16:58:51 EDT 2023
Status for the jail: nginx-req-limit
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/error.log /home/nginx/domains/log4j.domain.com/log/error.log /home/nginx/domains/domain2.com/log/error.log /home/nginx/domains/demodomain.com/log/error.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-req-limit-main parameters: 
maxretry: 5 findtime: 600 bantime: 7200
allow rate: 576 hits/day
filter last modified: Thu Apr  6 16:58:51 EDT 2023
Status for the jail: nginx-req-limit-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.error.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-xmlrpc parameters: 
maxretry: 6 findtime: 60 bantime: 600
allow rate: 7200 hits/day
filter last modified: Thu Apr  6 16:58:53 EDT 2023
Status for the jail: nginx-xmlrpc
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
nginx-xmlrpc-main parameters: 
maxretry: 6 findtime: 60 bantime: 600
allow rate: 7200 hits/day
filter last modified: Thu Apr  6 16:58:53 EDT 2023
Status for the jail: nginx-xmlrpc-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
shells parameters: 
maxretry: 1 findtime: 86400 bantime: 604800
allow rate: 1 hits/day
filter last modified: Thu Apr  6 16:59:03 EDT 2023
Status for the jail: shells
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
shells-main parameters: 
maxretry: 1 findtime: 86400 bantime: 604800
allow rate: 1 hits/day
filter last modified: Thu Apr  6 16:59:03 EDT 2023
Status for the jail: shells-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
vbulletin parameters: 
maxretry: 3 findtime: 60 bantime: 28800
allow rate: 2880 hits/day
filter last modified: Thu Apr  6 16:58:55 EDT 2023
Status for the jail: vbulletin
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
vbulletin-main parameters: 
maxretry: 3 findtime: 60 bantime: 28800
allow rate: 2880 hits/day
filter last modified: Thu Apr  6 16:58:55 EDT 2023
Status for the jail: vbulletin-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
wordpress-auth parameters: 
maxretry: 3 findtime: 60 bantime: 600
allow rate: 2880 hits/day
filter last modified: Thu Apr  6 16:58:56 EDT 2023
Status for the jail: wordpress-auth
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
wordpress-auth-main parameters: 
maxretry: 3 findtime: 60 bantime: 600
allow rate: 2880 hits/day
filter last modified: Thu Apr  6 16:58:56 EDT 2023
Status for the jail: wordpress-auth-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
wordpress-comment parameters: 
maxretry: 5 findtime: 60 bantime: 3600
allow rate: 5760 hits/day
filter last modified: Thu Apr  6 16:58:57 EDT 2023
Status for the jail: wordpress-comment
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
wordpress-comment-main parameters: 
maxretry: 5 findtime: 60 bantime: 3600
allow rate: 5760 hits/day
filter last modified: Thu Apr  6 16:58:57 EDT 2023
Status for the jail: wordpress-comment-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
wordpress-fail2ban-plugin parameters: 
maxretry: 1 findtime: 7200 bantime: 259200
allow rate: 12 hits/day
filter last modified: Thu Apr  6 16:59:02 EDT 2023
Status for the jail: wordpress-fail2ban-plugin
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/auth.log /var/log/secure
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
wordpress-pingback parameters: 
maxretry: 1 findtime: 1 bantime: 86400
allow rate: 1 hits/day
filter last modified: Thu Apr  6 16:58:58 EDT 2023
Status for the jail: wordpress-pingback
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/nginx/domains/domain.com/log/access.log /home/nginx/domains/log4j.domain.com/log/access.log /home/nginx/domains/domain2.com/log/access.log /home/nginx/domains/demodomain.com/log/access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
wordpress-pingback-main parameters: 
maxretry: 1 findtime: 1 bantime: 86400
allow rate: 1 hits/day
filter last modified: Thu Apr  6 16:58:58 EDT 2023
Status for the jail: wordpress-pingback-main
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/nginx/localhost.access.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
wordpress-pingback-repeat parameters: 
maxretry: 5 findtime: 21600 bantime: 259200
allow rate: 16 hits/day
filter last modified: Thu Apr  6 16:58:59 EDT 2023
Status for the jail: wordpress-pingback-repeat
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/fail2ban.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
---------------------------------------
All Time: Top 10 Banned IP Addresses:
      1 192.xxx.xxx.xxx [nginx-log4j]
      1 159.203.xxx.xxx [nginx-common-main]
---------------------------------------
All Time: Top 10 Restored Banned IP Addresses:
---------------------------------------
Yesterday: Top 10 Banned IP Addresses:
      1 192.xxx.xxx.xxx [nginx-log4j]
---------------------------------------
Yesterday: Top 10 Restored Banned IP Addresses:
---------------------------------------
Today: Top 10 Banned IP Addresses:
      1 159.203.xxx.xxx [nginx-common-main]
---------------------------------------
Today: Top 10 Restored Banned IP Addresses:
---------------------------------------
1 hr ago: Top 10 Banned IP Addresses:
      1 159.203.xxx.xxx [nginx-common-main]
---------------------------------------
1 hr ago: Top 10 Restored Banned IP Addresses:
---------------------------------------
```

```
ls -lAh /etc/fail2ban/filter.d/
total 576K
-rw-r--r-- 1 root root  467 Apr  6 17:07 3proxy.conf
-rw-r--r-- 1 root root  578 Apr  6 16:59 adminer.conf
-rw-r--r-- 1 root root  581 Apr  6 16:59 adminer-main.conf
-rw-r--r-- 1 root root 3.2K Apr  6 17:07 apache-auth.conf
-rw-r--r-- 1 root root 2.8K Apr  6 17:07 apache-badbots.conf
-rw-r--r-- 1 root root 1.3K Apr  6 17:07 apache-botsearch.conf
-rw-r--r-- 1 root root 1.6K Apr  6 17:07 apache-common.conf
-rw-r--r-- 1 root root  403 Apr  6 17:07 apache-fakegooglebot.conf
-rw-r--r-- 1 root root  511 Apr  6 17:07 apache-modsecurity.conf
-rw-r--r-- 1 root root  596 Apr  6 17:07 apache-nohome.conf
-rw-r--r-- 1 root root 1.3K Apr  6 17:07 apache-noscript.conf
-rw-r--r-- 1 root root 2.2K Apr  6 17:07 apache-overflows.conf
-rw-r--r-- 1 root root  362 Apr  6 17:07 apache-pass.conf
-rw-r--r-- 1 root root 1020 Apr  6 17:07 apache-shellshock.conf
-rw-r--r-- 1 root root 3.5K Apr  6 17:07 assp.conf
-rw-r--r-- 1 root root 2.4K Apr  6 17:07 asterisk.conf
-rw-r--r-- 1 root root  427 Apr  6 17:07 bitwarden.conf
-rw-r--r-- 1 root root  522 Apr  6 17:07 botsearch-common.conf
-rw-r--r-- 1 root root  307 Apr  6 17:07 centreon.conf
-rw-r--r-- 1 root root 2.8K Apr  6 17:07 common.conf
-rw-r--r-- 1 root root  244 Apr  6 17:07 counter-strike.conf
-rw-r--r-- 1 root root  463 Apr  6 17:07 courier-auth.conf
-rw-r--r-- 1 root root  512 Apr  6 17:07 courier-smtp.conf
-rw-r--r-- 1 root root  444 Apr  6 17:07 cyrus-imap.conf
-rw-r--r-- 1 root root  338 Apr  6 17:07 directadmin.conf
-rw-r--r-- 1 root root 2.1K Apr  6 17:07 domino-smtp.conf
-rw-r--r-- 1 root root 2.6K Apr  6 17:07 dovecot.conf
-rw-r--r-- 1 root root 1.7K Apr  6 17:07 dropbear.conf
-rw-r--r-- 1 root root  547 Apr  6 17:07 drupal-auth.conf
-rw-r--r-- 1 root root 1.6K Apr  6 17:07 ejabberd-auth.conf
-rw-r--r-- 1 root root  534 Apr  6 17:07 exim-common.conf
-rw-r--r-- 1 root root 2.9K Apr  6 17:07 exim.conf
-rw-r--r-- 1 root root 2.2K Apr  6 17:07 exim-spam.conf
-rw-r--r-- 1 root root 1.9K Apr  6 17:07 freeswitch.conf
-rw-r--r-- 1 root root 1.2K Apr  6 17:07 froxlor-auth.conf
-rw-r--r-- 1 root root  236 Apr  6 17:07 gitlab.conf
-rw-r--r-- 1 root root  388 Apr  6 17:07 grafana.conf
-rw-r--r-- 1 root root  236 Apr  6 17:07 groupoffice.conf
-rw-r--r-- 1 root root  322 Apr  6 17:07 gssftpd.conf
-rw-r--r-- 1 root root 1.5K Apr  6 17:07 guacamole.conf
-rw-r--r-- 1 root root 1.2K Apr  6 17:07 haproxy-http-auth.conf
-rw-r--r-- 1 root root  404 Apr  6 17:07 horde.conf
-rw-r--r-- 1 root root  900 Apr  6 16:58 http-xensec.conf
-rw-r--r-- 1 root root  901 Apr  6 16:58 http-xensec-main.conf
drwxr-xr-x 2 root root 4.0K Apr  6 17:13 ignorecommands
-rw-r--r-- 1 root root  308 Apr  6 16:59 joomla-auth.conf
-rw-r--r-- 1 root root  309 Apr  6 16:59 joomla-auth-main.conf
-rw-r--r-- 1 root root  938 Apr  6 17:07 kerio.conf
-rw-r--r-- 1 root root  459 Apr  6 17:07 lighttpd-auth.conf
-rw-r--r-- 1 root root  288 Apr  6 16:59 magento.conf
-rw-r--r-- 1 root root  289 Apr  6 16:59 magento-main.conf
-rw-r--r-- 1 root root 2.3K Apr  6 17:07 mongodb-auth.conf
-rw-r--r-- 1 root root  787 Apr  6 17:07 monit.conf
-rw-r--r-- 1 root root  640 Apr  6 17:07 monitorix.conf
-rw-r--r-- 1 root root  441 Apr  6 17:07 mssql-auth.conf
-rw-r--r-- 1 root root  927 Apr  6 17:07 murmur.conf
-rw-r--r-- 1 root root  953 Apr  6 17:07 mysqld-auth.conf
-rw-r--r-- 1 root root  400 Apr  6 17:07 nagios.conf
-rw-r--r-- 1 root root 1.6K Apr  6 17:07 named-refused.conf
-rw-r--r-- 1 root root  240 Apr  6 16:58 nginx-401.conf
-rw-r--r-- 1 root root  241 Apr  6 16:58 nginx-401-main.conf
-rw-r--r-- 1 root root  240 Apr  6 16:58 nginx-403.conf
-rw-r--r-- 1 root root  241 Apr  6 16:58 nginx-403-main.conf
-rw-r--r-- 1 root root  240 Apr  6 16:58 nginx-404.conf
-rw-r--r-- 1 root root  241 Apr  6 16:58 nginx-404-main.conf
-rw-r--r-- 1 root root  579 Apr  6 16:58 nginx-auth.conf
-rw-r--r-- 1 root root  587 Apr  6 16:58 nginx-auth-main.conf
-rw-r--r-- 1 root root  474 Apr  6 17:07 nginx-bad-request.conf
-rw-r--r-- 1 root root  409 Apr  6 16:58 nginx-badrequests.conf
-rw-r--r-- 1 root root  410 Apr  6 16:58 nginx-badrequests-main.conf
-rw-r--r-- 1 root root  740 Apr  6 17:07 nginx-botsearch.conf
-rw-r--r-- 1 root root  855 Apr  6 16:58 nginx-botsearch-main.conf
-rw-r--r-- 1 root root  321 Apr  6 16:58 nginx-common.conf
-rw-r--r-- 1 root root  322 Apr  6 16:58 nginx-common-main.conf
-rw-r--r-- 1 root root  257 Apr  6 16:58 nginx-conn-limit.conf
-rw-r--r-- 1 root root  267 Apr  6 16:58 nginx-conn-limit-main.conf
-rw-r--r-- 1 root root  224 Apr  6 16:58 nginx-get-f5.conf
-rw-r--r-- 1 root root  225 Apr  6 16:58 nginx-get-f5-main.conf
-rw-r--r-- 1 root root 1.1K Apr  6 17:07 nginx-http-auth.conf
-rw-r--r-- 1 root root 1.5K Apr  6 17:07 nginx-limit-req.conf
-rw-r--r-- 1 root root  623 Apr  6 16:58 nginx-log4j.conf
-rw-r--r-- 1 root root  633 Apr  6 16:58 nginx-log4j-main.conf
-rw-r--r-- 1 root root 1.6K Apr  6 16:58 nginx-req-limit.conf
-rw-r--r-- 1 root root 1.6K Apr  6 16:58 nginx-req-limit-main.conf
-rw-r--r-- 1 root root  257 Apr  6 16:58 nginx-req-limit-repeat.conf
-rw-r--r-- 1 root root  256 Apr  6 16:58 nginx-w00tw00t.conf
-rw-r--r-- 1 root root  257 Apr  6 16:58 nginx-w00tw00t-main.conf
-rw-r--r-- 1 root root  223 Apr  6 16:58 nginx-xmlrpc.conf
-rw-r--r-- 1 root root  224 Apr  6 16:58 nginx-xmlrpc-main.conf
-rw-r--r-- 1 root root  779 Apr  6 17:07 nsd.conf
-rw-r--r-- 1 root root  452 Apr  6 17:07 openhab.conf
-rw-r--r-- 1 root root  495 Apr  6 17:07 openwebmail.conf
-rw-r--r-- 1 root root 1.9K Apr  6 17:07 oracleims.conf
-rw-r--r-- 1 root root  947 Apr  6 17:07 pam-generic.conf
-rw-r--r-- 1 root root  568 Apr  6 17:07 perdition.conf
-rw-r--r-- 1 root root  493 Apr  6 16:58 phpmyadmin-cmm.conf
-rw-r--r-- 1 root root  569 Apr  6 16:59 phpmyadmin-other.conf
-rw-r--r-- 1 root root  278 Apr  6 17:07 phpmyadmin-syslog.conf
-rw-r--r-- 1 root root  891 Apr  6 17:07 php-url-fopen.conf
-rw-r--r-- 1 root root  242 Apr  6 17:07 portsentry.conf
-rw-r--r-- 1 root root 3.2K Apr  6 17:07 postfix.conf
-rw-r--r-- 1 root root 1.2K Apr  6 17:07 proftpd.conf
-rw-r--r-- 1 root root 2.4K Apr  6 17:07 pure-ftpd.conf
-rw-r--r-- 1 root root  795 Apr  6 17:07 qmail.conf
-rw-r--r-- 1 root root 1.4K Apr  6 17:07 recidive.conf
-rw-r--r-- 1 root root 1.5K Apr  6 17:07 roundcube-auth.conf
-rw-r--r-- 1 root root  354 Apr  6 17:07 scanlogd.conf
-rw-r--r-- 1 root root  821 Apr  6 17:07 screensharingd.conf
-rw-r--r-- 1 root root  538 Apr  6 17:07 selinux-common.conf
-rw-r--r-- 1 root root  570 Apr  6 17:07 selinux-ssh.conf
-rw-r--r-- 1 root root  790 Apr  6 17:07 sendmail-auth.conf
-rw-r--r-- 1 root root 3.0K Apr  6 17:07 sendmail-reject.conf
-rw-r--r-- 1 root root  319 Apr  6 16:59 shells.conf
-rw-r--r-- 1 root root  320 Apr  6 16:59 shells-main.conf
-rw-r--r-- 1 root root  371 Apr  6 17:07 sieve.conf
-rw-r--r-- 1 root root  706 Apr  6 17:07 slapd.conf
-rw-r--r-- 1 root root  451 Apr  6 17:07 softethervpn.conf
-rw-r--r-- 1 root root  722 Apr  6 17:07 sogo-auth.conf
-rw-r--r-- 1 root root 1.1K Apr  6 17:07 solid-pop3d.conf
-rw-r--r-- 1 root root  260 Apr  6 17:07 squid.conf
-rw-r--r-- 1 root root  191 Apr  6 17:07 squirrelmail.conf
-rw-r--r-- 1 root root 7.7K Apr  6 17:07 sshd.conf
-rw-r--r-- 1 root root  363 Apr  6 17:07 stunnel.conf
-rw-r--r-- 1 root root  649 Apr  6 17:07 suhosin.conf
-rw-r--r-- 1 root root  890 Apr  6 17:07 tine20.conf
-rw-r--r-- 1 root root 2.4K Apr  6 17:07 traefik-auth.conf
-rw-r--r-- 1 root root  374 Apr  6 17:07 uwimap-auth.conf
-rw-r--r-- 1 root root  260 Apr  6 16:58 vbulletin.conf
-rw-r--r-- 1 root root  261 Apr  6 16:58 vbulletin-main.conf
-rw-r--r-- 1 root root  637 Apr  6 17:07 vsftpd.conf
-rw-r--r-- 1 root root  444 Apr  6 17:07 webmin-auth.conf
-rw-r--r-- 1 root root  240 Apr  6 16:58 wordpress-auth.conf
-rw-r--r-- 1 root root  241 Apr  6 16:58 wordpress-auth-main.conf
-rw-r--r-- 1 root root  254 Apr  6 16:58 wordpress-comment.conf
-rw-r--r-- 1 root root  255 Apr  6 16:58 wordpress-comment-main.conf
-rw-r--r-- 1 root root  672 Apr  6 16:59 wordpress-fail2ban-plugin.conf
-rw-r--r-- 1 root root  287 Apr  6 16:58 wordpress-pingback.conf
-rw-r--r-- 1 root root  288 Apr  6 16:58 wordpress-pingback-main.conf
-rw-r--r-- 1 root root  266 Apr  6 16:58 wordpress-pingback-repeat.conf
-rw-r--r-- 1 root root  520 Apr  6 17:07 wuftpd.conf
-rw-r--r-- 1 root root  521 Apr  6 17:07 xinetd-fail.conf
-rw-r--r-- 1 root root  912 Apr  6 17:07 znc-adminlog.conf
-rw-r--r-- 1 root root 1.2K Apr  6 17:07 zoneminder.conf
```