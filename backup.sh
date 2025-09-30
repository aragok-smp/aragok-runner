#!/usr/bin/env bash
set -euo pipefail

# --- Check required environment variables ---
required_vars=(RESTIC_REPO RESTIC_PASSWORD_FILE BACKUP_SOURCE LOGFILE)

for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: environment variable $var is not set." >&2
        exit 1
    fi
done

# Export vars for restic
export RESTIC_REPOSITORY="$RESTIC_REPO"
export RESTIC_PASSWORD_FILE

# Ensure log directory exists
mkdir -p "$(dirname "$LOGFILE")"

# --- Pre-flight checks ---
if ! command -v restic &>/dev/null; then
    echo "Error: restic is not installed." | tee -a "$LOGFILE" >&2
    exit 1
fi

# Ensure password file exists
if [[ ! -f "$RESTIC_PASSWORD_FILE" ]]; then
    echo "Error: password file '$RESTIC_PASSWORD_FILE' not found." | tee -a "$LOGFILE" >&2
    exit 1
fi

# Ensure backup source exists
if [[ ! -e "$BACKUP_SOURCE" ]]; then
    echo "[$(date '+%F %T')] Error: backup source '$BACKUP_SOURCE' does not exist." | tee -a "$LOGFILE" >&2
    exit 1
fi

# --- Check if repository is initialized ---
echo "[$(date '+%F %T')] Checking restic repository at '$RESTIC_REPO'..." | tee -a "$LOGFILE"

set +e
restic_out=$(restic -r "$RESTIC_REPO" cat config 2>&1)
restic_rc=$?
set -e

if [[ $restic_rc -eq 0 ]]; then
    echo "[$(date '+%F %T')] Repository already initialized." | tee -a "$LOGFILE"
elif [[ $restic_rc -eq 10 ]] || echo "$restic_out" | grep -qiE 'repository does not exist|unable to open config file|no such file or directory'; then
    echo "[$(date '+%F %T')] Repository not found; initializing..." | tee -a "$LOGFILE"
    restic -r "$RESTIC_REPO" init | tee -a "$LOGFILE"
else
    echo "[$(date '+%F %T')] Error checking repository (exit code $restic_rc)." | tee -a "$LOGFILE" >&2
    echo "$restic_out" | tee -a "$LOGFILE" >&2
    exit 1
fi

# --- Backup ---
echo "[$(date '+%F %T')] Starting backup of '$BACKUP_SOURCE'..." | tee -a "$LOGFILE"
if restic -r "$RESTIC_REPO" backup "$BACKUP_SOURCE" --skip-if-unchanged --verbose | tee -a "$LOGFILE"; then
    echo "[$(date '+%F %T')] Backup completed successfully." | tee -a "$LOGFILE"
else
    echo "[$(date '+%F %T')] Backup failed." | tee -a "$LOGFILE" >&2
    exit 1
fi

# --- Retention policy ---
echo "[$(date '+%F %T')] Applying retention policy and pruning..." | tee -a "$LOGFILE"
restic -r "$RESTIC_REPO" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune | tee -a "$LOGFILE"

echo "[$(date '+%F %T')] Done." | tee -a "$LOGFILE"
