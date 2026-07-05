#!/usr/bin/env bash
# AI OS machine-layer installer (macOS/Linux) — IDEMPOTENT. Mirrors install.ps1.
# Re-installs / re-syncs every global Claude Code tool. Safe to run repeatedly.
#   bash install.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info(){ printf '\033[36m[ai-os]\033[0m %s\n' "$1"; }
ok(){   printf '   \033[32mOK\033[0m %s\n' "$1"; }
warn(){ printf '   \033[33m!!\033[0m %s\n' "$1"; }

# 1. uv (package manager for global CLI tools)
if ! command -v uv >/dev/null 2>&1; then
  info "installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null 2>&1 && ok "uv $(uv --version)" || { echo "uv install failed"; exit 1; }

# 2. spec-kit CLI (specify) — spec-driven development
info "installing/updating spec-kit CLI (specify)..."
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --python 3.13 --force
command -v specify >/dev/null 2>&1 && ok "specify $(specify --version 2>/dev/null || echo installed)" \
  || warn "specify not on PATH (add ~/.local/bin to PATH)"

# 3. superpowers — Claude Code plugin (user scope, global)
info "installing/updating superpowers plugin..."
if command -v claude >/dev/null 2>&1; then
  # migrate off the old superpowers-marketplace coordinate (ai-os uses the official one at project scope)
  claude plugin uninstall superpowers@superpowers-marketplace >/dev/null 2>&1 || true
  if claude plugin install superpowers@claude-plugins-official >/dev/null 2>&1; then
    ok "superpowers installed/enabled (restart Claude Code to apply if just added)"
  else warn "plugin install (likely already installed)"; fi
else
  warn "claude CLI not found — skipping superpowers (install Claude Code, then re-run)"
fi

# 4. skills -> ~/.claude/skills  (every dir under skills/)
info "deploying skills to ~/.claude/skills ..."
mkdir -p "$HOME/.claude/skills"
count=0
for d in "$HERE"/skills/*/; do
  name="$(basename "$d")"
  rm -rf "$HOME/.claude/skills/$name"
  cp -R "${d%/}" "$HOME/.claude/skills/$name"
  count=$((count+1))
done
ok "$count skill(s) deployed to ~/.claude/skills"

# 5. subagents -> ~/.claude/agents
info "deploying subagents to ~/.claude/agents ..."
mkdir -p "$HOME/.claude/agents"
cp -f "$HERE"/agents/*.md "$HOME/.claude/agents/"
ok "$(ls -1 "$HERE"/agents/*.md | wc -l | tr -d ' ') subagents deployed to ~/.claude/agents"

# 6. Magic MCP (21st.dev) — needs TWENTY_FIRST_API_KEY; never commit the key
info "configuring Magic MCP (user scope)..."
if [ -n "${TWENTY_FIRST_API_KEY:-}" ] && command -v claude >/dev/null 2>&1; then
  if claude mcp add magic --scope user --env "API_KEY=$TWENTY_FIRST_API_KEY" -- npx -y '@21st-dev/magic@latest' >/dev/null 2>&1; then
    ok "Magic MCP configured (user scope)"
  else warn "Magic MCP add (likely already present)"; fi
else
  warn "TWENTY_FIRST_API_KEY not set (or no claude CLI) — skipping Magic MCP (key at https://21st.dev)"
fi

# 7. AI OS Dashboard — Windows-only for now
info "AI OS Dashboard is Windows-only for now — skipping (PowerShell 5.1 generator + desktop shortcut)."

# guard-destructive hook: VENDORED ONLY, intentionally NOT enabled (see MANIFEST.md section 6)
info "guard-destructive hook is vendored but OFF by default (see MANIFEST.md to enable)."
info "Done. Per-project spec-kit:  specify init --here --integration claude --script sh --force"
