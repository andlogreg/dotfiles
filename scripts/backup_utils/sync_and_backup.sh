#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# This script requires a 'config.sh' file to be present in the same directory.
# This file must define all required environment variables (e.g., DVC_REPO_PATH,
# LOCAL_RESTIC_REPO).
# ---------------------------------------------------------------------------
if [ -f config.sh ]; then
    source config.sh
    echo "✅ Configuration loaded from config.sh"
else
    echo "❌ ERROR: config.sh not found. Please create it (e.g., from config.sh.example)."
    exit 1
fi

(
    # MANDATORY: Set the local Restic repository path for all local operations
    export RESTIC_REPOSITORY="$LOCAL_RESTIC_REPO"

    echo "Welcome! Starting backup process..."
    echo "Items included in this run:"
    echo " - DVC files (add/commit)"
    echo " - DVC/Git backend directories"
    echo " - Photos backend directory"
    echo " "

    # === 1. Sync & Commit DVC Repo ===
    cd "$DVC_REPO_PATH"
    echo "🔄 Checking DVC repo: $DVC_REPO_PATH"
    dvc status

    read -rp "🟡 Do you want to proceed with adding, committing, and backing up DVC files? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "❌ DVC operation cancelled."
        exit 1
    fi
    echo "➕ Adding changes to DVC..."

    dvc add main_files
    echo "✅ Committing DVC file to Git..."
    git add main_files.dvc
    git commit -m "Auto commit: update on $(date '+%Y-%m-%d %H:%M:%S')" || echo "⚠️ No changes to commit."
    echo "✅ Git commit complete."


    # === 2. Restic Backup: Core ===
    echo " "
    echo "🗄️ Starting local Restic backup to: $LOCAL_RESTIC_REPO"

    # Ask for Restic Password Once (Local Repo)
    read -s -p "🔐 Enter >local< repo password: " RESTIC_LOCAL_PASSWORD_INPUT
    export RESTIC_PASSWORD="$RESTIC_LOCAL_PASSWORD_INPUT"

    # Build the backup command array with all source paths.
    # The Obsidian vault is deliberately absent: it is a git repository with its
    # own remote, and that remote is what protects it.
    BACKUP_CMD=(restic backup
        --exclude="*.DS_Store"
        --exclude-file="$PHOTOS_BACKEND_PATH/restic_excludes.txt"
        --verbose
        "$DVC_REPO_PATH"
        "$DVC_BACKEND_PATH"
        "$PHOTOS_BACKEND_PATH"
    )

    echo -e "\n📋 Backup command preview:"
    printf '  %s\n' "${BACKUP_CMD[@]}"
    echo
    read -rp "🟡 Proceed with this full restic backup? (y/N) " doBackup
    if [[ "$doBackup" =~ ^[Yy]$ ]]; then
        "${BACKUP_CMD[@]}"
        echo "✅ Backup complete."
    else
        echo "❌ Backup skipped."
    fi

    # === 3. Optional Integrity Check ===
    echo " "
    echo "✅ Verifying restic backup (check)..."
    restic check || echo "⚠️ Restic check reported issues. Investigate!"

    # === 4. Optional Pruning of Local Repo ===
    echo " "
    read -rp "🟡 Prune old snapshots from the local restic repo? (y/N) " pruneConfirm
    if [[ "$pruneConfirm" == "y" || "$pruneConfirm" == "Y" ]]; then
        echo "🧹 Pruning local repo..."
        restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
    else
        echo "ℹ️ Pruning skipped."
    fi

    # === 5. Replication to External + Cloud ===
    echo " "
    read -rp "🟡 Replicate snapshots to external/cloud repos? (y/N) " replicateConfirm
    if [[ "$replicateConfirm" == "y" || "$replicateConfirm" == "Y" ]]; then
        echo " "
        echo "🔄 Replicating snapshots to external drive..."
        if mount | grep -q "$EXTERNAL_DRIVE_NAME"; then
            echo "Found drive '$EXTERNAL_DRIVE_NAME'."
            read -s -p "🔐 Enter >external< repo password: " RESTIC_EXTERNAL_PASSWORD_INPUT

            export RESTIC_PASSWORD="$RESTIC_EXTERNAL_PASSWORD_INPUT"
            export RESTIC_FROM_PASSWORD="$RESTIC_LOCAL_PASSWORD_INPUT"

            if restic -r "$EXTERNAL_RESTIC_REPO" copy --from-repo "$LOCAL_RESTIC_REPO"; then
                echo "✅ External drive replication done."
                read -rp "🟡 Prune external repo too? (y/N) " pruneExt
                if [[ "$pruneExt" == "y" || "$pruneExt" == "Y" ]]; then
                    restic -r "$EXTERNAL_RESTIC_REPO" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
                fi
            else
                echo "⚠️ Could not replicate to external repo (error during copy). Check path: $EXTERNAL_RESTIC_REPO"
            fi
        else
            echo "⚠️ External drive not mounted (checking for: $EXTERNAL_DRIVE_NAME), skipping external replication."
        fi

        # --- Cloud Replication ---
        echo " "
        echo "🔄 Replicating to cloud repo: $CLOUD_RESTIC_REPO"
        read -s -p "🔐 Enter >cloud< repo password: " RESTIC_CLOUD_PASSWORD_INPUT

        export RESTIC_PASSWORD="$RESTIC_CLOUD_PASSWORD_INPUT"
        export RESTIC_FROM_PASSWORD="$RESTIC_LOCAL_PASSWORD_INPUT"

        if restic -r "$CLOUD_RESTIC_REPO" copy --from-repo "$LOCAL_RESTIC_REPO"; then
            echo "✅ Cloud repo replication done."
            read -rp "🟡 Prune cloud repo too? (y/N) " pruneCloud
            if [[ "$pruneCloud" == "y" || "$pruneCloud" == "Y" ]]; then
                restic -r "$CLOUD_RESTIC_REPO" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
            fi
        else
            echo "⚠️ Could not replicate to cloud repo (error during copy). Check rclone configuration/credentials."
        fi
    else
        echo "ℹ️ Snapshot replication skipped."
    fi

    # === 6. Cleanup & Finish ===
    # Unset all sensitive password variables from the environment
    unset RESTIC_PASSWORD
    unset RESTIC_FROM_PASSWORD
    echo " "
    echo "🎉 All done!"
)
