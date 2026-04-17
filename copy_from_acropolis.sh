#!/bin/bash
# Copy results/output from Acropolis to local machine
# Run from local machine

set -e  # Exit on error

# ===== PATHS =====
ACROPOLIS="acropolis"
REMOTE_PROJECT="/home/ksadovi/transit_credit-access"
LOCAL_PROJECT="/Users/kyrasadovi/Documents/research/transit_credit-access"

# Menu for what to copy
echo ""
echo "What would you like to pull from Acropolis?"
echo "  (1) Pull results / output folder"
echo "  (2) Pull logs"
echo "  (3) Custom pull"
read choice

if [ "$choice" = "1" ]; then
    REMOTE_PATH="${REMOTE_PROJECT}/output/"
    LOCAL_PATH="${LOCAL_PROJECT}/output/"

    echo ""
    echo "Pulling output folder..."
    echo "  Remote: ${ACROPOLIS}:${REMOTE_PATH}"
    echo "  Local:  ${LOCAL_PATH}"

    mkdir -p "$LOCAL_PATH"
    rsync -avz --progress "${ACROPOLIS}:${REMOTE_PATH}" "$LOCAL_PATH"

elif [ "$choice" = "2" ]; then
    REMOTE_PATH="${REMOTE_PROJECT}/logs/"
    LOCAL_PATH="${LOCAL_PROJECT}/logs/"

    echo ""
    echo "Pulling logs..."
    echo "  Remote: ${ACROPOLIS}:${REMOTE_PATH}"
    echo "  Local:  ${LOCAL_PATH}"

    mkdir -p "$LOCAL_PATH"
    rsync -avz --progress "${ACROPOLIS}:${REMOTE_PATH}" "$LOCAL_PATH"

elif [ "$choice" = "3" ]; then
    echo ""
    echo "Enter remote path (relative to ${REMOTE_PROJECT}/):"
    read remote_rel_path

    echo "Enter local destination path (relative to ${LOCAL_PROJECT}/):"
    read local_rel_path

    REMOTE_PATH="${REMOTE_PROJECT}/${remote_rel_path}"
    LOCAL_PATH="${LOCAL_PROJECT}/${local_rel_path}"

    echo ""
    echo "Copying custom path..."
    echo "  Remote: ${ACROPOLIS}:${REMOTE_PATH}"
    echo "  Local:  ${LOCAL_PATH}"

    mkdir -p "$(dirname "$LOCAL_PATH")"
    rsync -avz --progress "${ACROPOLIS}:${REMOTE_PATH}" "$LOCAL_PATH"

else
    echo "Invalid choice. Please select 1, 2, or 3."
    exit 1
fi

echo ""
echo "✓ Copy from Acropolis completed!"