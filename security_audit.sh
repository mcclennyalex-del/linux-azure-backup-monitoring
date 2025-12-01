#!/bin/bash
set -euo pipefail

echo "===== Security Audit (security_audit.sh) ====="
echo "Date:     $(date)"
echo "Hostname: $(hostname)"
echo

# 1. Recent logins
echo "---- Last 10 logins (last) ----"
last -n 10 || echo "last command not available"
echo

# 2. Failed logins (if lastb / btmp exists)
if command -v lastb &>/dev/null && [ -r /var/log/btmp ]; then
  echo "---- Last 10 failed logins (lastb) ----"
  lastb -n 10
  echo
fi

# 3. Users with real shells (non-system accounts)
echo "---- Users with shells (UID >= 1000) ----"
awk -F: '$3 >= 1000 {print $1 "\t" $7}' /etc/passwd
echo

# 4. World-writable files in /home and /var/www (can be noisy)
echo "---- World-writable files under /home and /var/www ----"
find /home /var/www -xdev -type f -perm -0002 2>/dev/null | head -n 50
echo "(showing first 50, if any)"
echo

# 5. Listening ports
echo "---- Listening ports (ss -tulnp) ----"
ss -tulnp 2>/dev/null || netstat -tulnp 2>/dev/null || echo "No ss/netstat available"
echo

# 6. Key SSH config values
SSHD_CONFIG="/etc/ssh/sshd_config"

if [ -r "$SSHD_CONFIG" ]; then
  echo "---- SSH daemon config checks ($SSHD_CONFIG) ----"
  egrep -i '^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)' "$SSHD_CONFIG" || \
    echo "No matching directives found (may be using defaults)."
else
  echo "Cannot read $SSHD_CONFIG"
fi

echo
echo "===== End of security audit ====="
