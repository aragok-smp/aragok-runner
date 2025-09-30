#!/usr/bin/env bash
set -euo pipefail

# --- Check required environment variables ---
required_vars=(RESTIC_REPOSITORY RESTIC_PASSWORD RESTIC_BACKUP_SOURCE RESTIC_LOGFILE)

for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: environment variable $var is not set." >&2
        exit 1
    fi
done

# Export vars for restic
export RESTIC_REPOSITORY
export RESTIC_PASSWORD

# Ensure log directory exists
mkdir -p "$(dirname "$RESTIC_LOGFILE")"

# --- Pre-flight checks ---
if ! command -v restic &>/dev/null; then
    echo "Error: restic is not installed." | tee -a "$RESTIC_LOGFILE" >&2
    exit 1
fi

# Ensure password exists
if [[ ! -e "$RESTIC_PASSWORD" ]]; then
    echo "Error: password '$RESTIC_PASSWORD' not found." | tee -a "$RESTIC_LOGFILE" >&2
    exit 1
fi

# Ensure backup source exists
if [[ ! -e "$RESTIC_BACKUP_SOURCE" ]]; then
    echo "[$(date '+%F %T')] Error: backup source '$RESTIC_BACKUP_SOURCE' does not exist." | tee -a "$RESTIC_LOGFILE" >&2
    exit 1
fi

# --- Check if repository is initialized ---
echo "[$(date '+%F %T')] Checking restic repository at '$RESTIC_REPOSITORY'..." | tee -a "$RESTIC_LOGFILE"

set +e
restic_out=$(restic cat config 2>&1)
restic_rc=$?
set -e

if [[ $restic_rc -eq 0 ]]; then
    echo "[$(date '+%F %T')] Repository already initialized." | tee -a "$RESTIC_LOGFILE"
elif [[ $restic_rc -eq 10 ]]; then
    echo "[$(date '+%F %T')] Repository not found; initializing..." | tee -a "$RESTIC_LOGFILE"
    restic init | tee -a "$RESTIC_LOGFILE"
else
    echo "[$(date '+%F %T')] Error checking repository (exit code $restic_rc)." | tee -a "$RESTIC_LOGFILE" >&2
    echo "$restic_out" | tee -a "$RESTIC_LOGFILE" >&2
    exit 1
fi

# --- Backup ---
echo "[$(date '+%F %T')] Starting backup of '$RESTIC_BACKUP_SOURCE'..." | tee -a "$RESTIC_LOGFILE"
if restic backup "$RESTIC_BACKUP_SOURCE" --skip-if-unchanged --verbose | tee -a "$RESTIC_LOGFILE"; then
    echo "[$(date '+%F %T')] Backup completed successfully." | tee -a "$RESTIC_LOGFILE"
else
    echo "[$(date '+%F %T')] Backup failed." | tee -a "$RESTIC_LOGFILE" >&2
    exit 1
fi

# --- Retention policy ---
echo "[$(date '+%F %T')] Applying retention policy and pruning..." | tee -a "$RESTIC_LOGFILE"
if restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune | tee -a "$RESTIC_LOGFILE"; then
    echo "[$(date '+%F %T')] Retention policy applied successfully." | tee -a "$RESTIC_LOGFILE"
else
    echo "[$(date '+%F %T')] Retention policy application failed." | tee -a "$RESTIC_LOGFILE" >&2
    exit 1
fi

echo "[$(date '+%F %T')] Done." | tee -a "$RESTIC_LOGFILE"
