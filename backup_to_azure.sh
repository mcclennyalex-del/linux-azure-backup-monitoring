#!/bin/bash
# backup_to_azure.sh
# Sync a local projects folder from Fedora to an Azure VM using rsync over SSH.

set -euo pipefail

# === Config ===
# Local folder you want to protect
SOURCE_DIR="/home/karma/projects"

# Remote backup target on the Azure VM
DEST_USER="karma"
DEST_HOST="<AZURE_VM_IP>"           # <- replace with your VM IP or DNS
DEST_PATH="/home/karma/backups"

DEST="${DEST_USER}@${DEST_HOST}:${DEST_PATH}"

# Optional: log file on the local machine
LOG_DIR="${HOME}/logs"
LOG_FILE="${LOG_DIR}/backup.log"

# === Prep ===
mkdir -p "${LOG_DIR}"

echo "[$(date '+%F %T')] Starting backup from ${SOURCE_DIR} to ${DEST}..."

# Make sure the backup directory exists on the Azure VM
ssh "${DEST_USER}@${DEST_HOST}" "mkdir -p ${DEST_PATH}"

# Run the rsync backup
rsync -avz --delete "${SOURCE_DIR}/" "${DEST}"

echo "[$(date '+%F %T')] Backup complete." | tee -a "${LOG_FILE}"
