# Linux ↔ Azure Backup, Monitoring & Security Automation (Home Lab)

This repo documents a small home-lab style project where I:

- Run **Fedora Linux** in VirtualBox on my local machine  
- Run a **Rocky Linux VM in Azure**  
- Set up **SSH key-based authentication** between them  
- Use **Bash + rsync** to back up files from local → Azure  
- Use scripts on the Azure VM for **system monitoring** and **security auditing**  
- Automate everything with **cron jobs**

I also document issues I ran into (VirtualBox errors, SSH, cron, etc.) and how I fixed them, because that’s how I actually learned this stuff.

---

## 🔭 Project Goals

- Practice real-world Linux skills on both a **local VM** and a **cloud VM**  
- Automate backups using `rsync` over SSH  
- Monitor basic system health (CPU, RAM, disk, uptime, sessions)  
- Run lightweight security checks (failed logins, ports, services)  
- Use cron to schedule everything instead of running scripts manually  
- Learn how to troubleshoot common virtualization and Linux problems  

---

## 🧱 High-Level Architecture

```text
+------------------------+          SSH (key-based)         +-------------------------+
|  Local VM (Fedora)     |   rsync backups  +-------------> |  Azure VM (Rocky Linux) |
|                        |                 |                |                         |
| - backup_to_azure.sh   |                 |                | - monitor.sh            |
| - cron: nightly backup |                 |                | - security_audit.sh     |
|                        |                 |                | - cron: monitor + audit |
+------------------------+                 |                +-------------------------+
                                           |
                                           v
                                  /home/karma/backups


🖥️ Lab Environment
Local machine

OS: Windows 11 host

Virtualization: VirtualBox running Fedora (local VM)

User: karma

Used as the source of files (projects, notes, etc.)

Cloud side

Cloud: Personal Azure subscription

Compute: One Rocky Linux VM in Azure

User: karma (same username to keep things simple)

Used as the backup + monitoring target

Networking

SSH over the public IP of the Azure VM

NSG rule allowing TCP 22 from my home IP

SSH authentication: ed25519 key pair (~/.ssh/id_ed25519)

🧰 Scripts in This Repo
backup_to_azure.sh

Purpose
Syncs a local directory from my Fedora VM to the Azure VM using rsync over SSH.

Key variables

# Local directory I want to back up
SOURCE_DIR="/home/karma/projects"

# Remote path on the Azure VM
DEST="karma@<AZURE_VM_IP>:/home/karma/backups"

Backup command

rsync -avz --delete "$SOURCE_DIR" "$DEST"


SOURCE_DIR – local folder to protect

DEST – user + IP + path on the Azure VM

--delete keeps the backup in sync (removes files on Azure if they were deleted locally)

What it does

Ensures /home/karma/backups exists on the Azure VM

Mirrors the contents of ~/projects into that backup folder

Prints a “Backup complete” message with a timestamp

monitor.sh

Purpose
Lightweight system monitoring script that prints basic health info.

Checks include

CPU / load averages (e.g. from uptime or top/ps)

Memory usage (free -h)

Disk usage (df -h)

System uptime

Top 5 processes by CPU or memory

Example output (shortened)

===== System Monitor (monitor.sh) =====
Date: 2025-12-01 01:30:00
Hostname: karma-azure

CPU / Load:
  load average: 0.05 0.10 0.20

Memory:
  total   used   free  buff/cache  available
  ...

Disk:
  Filesystem  Size  Used Avail Use% Mounted on
  /dev/sda1   ...

Top processes:
  PID USER  %CPU %MEM COMMAND
  ...


How to run

bash monitor.sh
# or, if executable
./monitor.sh


(After: chmod +x monitor.sh.)

security_audit.sh

Purpose
Very simple security / hygiene check for the Azure VM.
This isn’t a real pentest tool – it’s just to practice thinking about security.

Things it checks

Last logins (last, lastb if available)

Accounts with a shell and no password lock

World-writable files under /home or /var/www (example)

Listening ports (ss -tulnp)

Basic SSH config settings from /etc/ssh/sshd_config, for example:

PermitRootLogin

PasswordAuthentication

File permissions on important files (e.g. ~/.ssh, authorized_keys)

Example usage

bash security_audit.sh | tee /home/karma/logs/security_audit_$(date +%F).log


This prints the report to the screen and saves it to a dated log file.

⏰ Cron Jobs (Automation)

I used crontab -e on each VM to automate the scripts.

Fedora VM (local)

Goal: run the backup script every night.

# Nightly backup of ~/projects to Azure (1:00 AM)
0 1 * * * /home/karma/backup_to_azure.sh >> /home/karma/logs/backup.log 2>&1

Azure VM

Goal: run monitoring and security checks on a schedule.

# System monitor every 5 minutes
*/5 * * * * /home/karma/monitor.sh >> /home/karma/logs/monitor.log 2>&1

# Security audit once a day at 02:00
0 2 * * * /home/karma/security_audit.sh >> /home/karma/logs/security_audit.log 2>&1

🚀 How to Run This (High Level)

These steps assume you have SSH working between your local Linux box and your Azure VM.

Clone this repo (on the machines where you want the scripts):

git clone https://github.com/mcclennyalex-del/linux-azure-backup-monitoring.git
cd linux-azure-backup-monitoring


Make the scripts executable:

chmod +x backup_to_azure.sh monitor.sh security_audit.sh


Edit paths & IPs at the top of the scripts so they match your setup:

SOURCE_DIR

DEST (replace <AZURE_VM_IP> with your VM’s IP or DNS name)

Any log file paths you want

Test manually first:

./backup_to_azure.sh
./monitor.sh
./security_audit.sh


If everything looks good, add the cron jobs with crontab -e on each VM.

🧠 What I Learned / Issues I Hit

This project wasn’t just the “happy path” – I hit a bunch of real problems.

1. VirtualBox & Hyper-V conflict

Symptom: VirtualBox VMs were failing with VERR_UNRESOLVED_ERROR / E_FAIL.

Cause: Hyper-V / virtualization features were enabled on Windows.

Fix: Disabled the Windows Hyper-V platform features and rebooted so VirtualBox could take over VT-x.

2. SSH key authentication

I accidentally started generating keys as root (sudo ssh-keygen), which put keys in /root/.ssh.

That broke login as my regular user.

Fix:

ssh-keygen -t ed25519
ssh-copy-id karma@<AZURE_VM_IP>


Re-generated an ed25519 key pair as my normal user and used ssh-copy-id to push the public key to the Azure VM.

3. Rsync hostname / connection errors

Got errors like hostname contains invalid characters and
connection unexpectedly closed (code 255).

My DEST variable had a typo / wrong format.

Fix:

DEST="karma@<AZURE_VM_IP>:/home/karma/backups"


Verified I could SSH manually first:

ssh karma@<AZURE_VM_IP>

4. Cron troubleshooting

At first it looked like cron wasn’t running my script.

Real problem: environment variables + PATH inside cron are very minimal.

Fixes:

Used full paths to scripts and binaries.

Sent stdout + stderr to log files so I could see errors:

0 1 * * * /home/karma/backup_to_azure.sh >> /home/karma/logs/backup.log 2>&1

✅ Future Ideas

Add email or Slack alerts when a backup or security audit fails.

Add a small HTML dashboard or Grafana panel for the monitor output.

Expand the security script to check for package updates, firewall rules, and CIS-style hardening.

If you’re reading this and want to run the same lab, feel free to open an issue or fork the repo.
