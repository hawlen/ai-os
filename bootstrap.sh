#!/usr/bin/env bash
# AI OS (machine layer) one-line bootstrap (macOS/Linux).
#
# On any Unix machine with git + Claude Code:
#   curl -fsSL https://raw.githubusercontent.com/hawlen/ai-os/main/bootstrap.sh | bash
#
# Clones (or updates) the hub, then runs the idempotent installer.
# Override the clone location with  AI_OS_DIR=/path  before running.
# (Repo was formerly named claude-tooling — existing ~/claude-tooling clones keep updating in place.)
set -euo pipefail

REPO="https://github.com/hawlen/ai-os.git"
if [ -n "${AI_OS_DIR:-}" ]; then DEST="$AI_OS_DIR"
elif [ -n "${CLAUDE_TOOLING_DIR:-}" ]; then DEST="$CLAUDE_TOOLING_DIR"
elif [ -d "$HOME/claude-tooling/.git" ]; then DEST="$HOME/claude-tooling"
else DEST="$HOME/ai-os"; fi

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
