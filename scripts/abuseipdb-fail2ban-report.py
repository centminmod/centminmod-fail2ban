#!/usr/bin/env python3

import sys
import re
import time
import sqlite3
import requests
from pathlib import Path
from urllib.parse import quote

REPORTED_IP_LIST_FILE = '/home/pi/abuseipdb-reported-ip-list'
FAIL2BAN_SQLITE_DB = '/var/lib/fail2ban/fail2ban.sqlite3'

APIKEY, COMMENT, IP, CATEGORIES, BANTIME = sys.argv[1:]

def main():
    reported_ip_list = Path(REPORTED_IP_LIST_FILE)
    ip_match = None

    if reported_ip_list.exists():
        with reported_ip_list.open() as f:
            for line in f:
                if f"IP={IP} L=" in line:
                    ip_match = line.strip()
                    break

    should_ban_ip = 1
    current_timestamp = int(time.time())

    if ip_match:
        ban_length = int(re.search(r'L=([0-9\-]+)', ip_match).group(1))
        
        conn = sqlite3.connect(FAIL2BAN_SQLITE_DB)
        cursor = conn.cursor()
        cursor.execute("SELECT timeofban FROM bans WHERE ip = ?", (IP,))
        time_of_ban = cursor.fetchone()
        conn.close()

        if time_of_ban and ((ban_length == -1 and ban_length == int(BANTIME)) or (time_of_ban[0] + ban_length > current_timestamp)):
            should_ban_ip = 0
        else:
            with reported_ip_list.open('r') as f:
                lines = f.readlines()

            with reported_ip_list.open('w') as f:
                for line in lines:
                    if f"IP={IP}" not in line:
                        f.write(line)

    if should_ban_ip == 1:
        with reported_ip_list.open('a') as f:
            f.write(f"IP={IP} L={BANTIME}\n")

        response = requests.post(
            'https://api.abuseipdb.com/api/v2/report',
            headers={
                'Accept': 'application/json',
                'Key': APIKEY,
            },
            data={
                'comment': COMMENT,
                'ip': quote(IP),  # Urlencode the IP address
                'categories': CATEGORIES,
            }
        )

        if response.status_code != 200:
            print(f"Error: Received status code {response.status_code} from AbuseIPDB API")


if __name__ == "__main__":
    main()
