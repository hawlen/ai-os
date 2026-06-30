#!/usr/bin/env bash
# claude-tooling one-line bootstrap (macOS/Linux).
#
# On any Unix machine with git + Claude Code:
#   curl -fsSL https://raw.githubusercontent.com/hawlen/claude-tooling/main/bootstrap.sh | bash
#
# Clones (or updates) the hub, then runs the idempotent installer.
# Override the clone location with  CLAUDE_TOOLING_DIR=/path  before running.
set -euo pipefail

REPO="https://github.com/hawlen/claude-tooling.git"
DEST="${CLAUDE_TOOLING_DIR:-$HOME/claude-tooling}"

command -v git >/dev/null 2>&1 || { echo "git is required. Install git and re-run."; exit 1; }

if [ -d "$DEST/.git" ]; then
  echo "[bootstrap] updating existing clone at $DEST"
  git -C "$DEST" pull --ff-only
else
  echo "[bootstrap] cloning hub to $DEST"
  git clone "$REPO" "$DEST"
fi

echo "[bootstrap] running installer..."
bash "$DEST/install.sh"
echo "[bootstrap] done. Hub at: $DEST"
