#!/bin/bash
#################################################
# for Centmin Mod newly created Nginx vhosts to
# register their logpaths in fail2ban, it requires
# fail2ban service restart
#################################################

# Check if fail2ban service is running
if systemctl is-active fail2ban >/dev/null 2>&1; then
  # Check if the nginx filter file exists
  if [ -f /etc/fail2ban/filter.d/nginx-common-main.conf ]; then
    # Restart fail2ban service silently
    systemctl restart fail2ban >/dev/null 2>&1
    echo "Fail2ban service restarted"
    echo "${1} vhost logpaths registered with Fail2ban"
  fi
fi
