#!/bin/bash
# Copy code and scripts from local to Acropolis server
# Run from the transit_credit-access repository root

set -e  # Exit on error

# Check if current directory is named "transit_credit-access"
if [ "$(basename "$PWD")" != "transit_credit-access" ]; then
    echo "Error: This script must be run from the 'transit_credit-access' directory"
    echo "Current directory: $(basename "$PWD")"
    exit 1
fi

# Get the directory where this script is located (repo root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ===== PATHS =====
ACROPOLIS="acropolis"
REMOTE_PROJECT="/home/ksadovi/transit_credit-access"

echo "======================================"
echo "Copying to Acropolis"
echo "  Local:  ${SCRIPT_DIR}"
echo "  Remote: ${ACROPOLIS}:${REMOTE_PROJECT}"
echo "======================================"

# Create remote project directory if it doesn't exist
echo "Creating remote directory structure..."
ssh "${ACROPOLIS}" "mkdir -p ${REMOTE_PROJECT}"

# Copy code (skip data/output/junk)
echo ""
echo "Copying code..."
rsync -avz --progress \
  --exclude='*.pyc' \
  --exclude='__pycache__/' \
  --exclude='.git/' \
  --exclude='1_data/' \
  --exclude='data/' \
  --exclude='output/' \
  --exclude='results/' \
  --exclude='.DS_Store' \
  "$SCRIPT_DIR/" \
  "${ACROPOLIS}:${REMOTE_PROJECT}/"

# Make shell scripts executable on remote
echo ""
echo "Making shell scripts executable on remote..."
ssh "${ACROPOLIS}" "find ${REMOTE_PROJECT} -maxdepth 2 -name '*.sh' -exec chmod +x {} \;"

echo ""
echo "======================================"
echo "✓ Copy to Acropolis completed!"
echo "======================================"
