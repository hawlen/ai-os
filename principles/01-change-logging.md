# AI OS Versioning & Change Logging

The AI OS repo uses a branch-per-machine model. `main` is the canonical orchestration and belongs to the admin PC alone. Every other PC logs its own evolution on its own branch, so all versions live on GitHub with explanations, and any PC can adopt or roll back to any logged version.

Rules for Claude Code on every machine:

1. **Never push `main` from this machine** unless the file `~/.ai-os-admin` exists (admin PC only). A git pre-push guard enforces this; do not work around it.
2. **Log every change.** After any change to AI OS files (principles, scripts) or any significant install/upgrade on this PC (new tools, dev stack, Claude Code plugins), run from the AI OS repo:
   `powershell -ExecutionPolicy Bypass -File sync.ps1 -Message "<one line: what was installed/changed and why>"`
   This appends to `machines/<PCNAME>/log.md`, commits as a version on `machine/<PCNAME>`, and pushes it to GitHub.
3. **Adopting a version** (from another PC's branch, from main, or any older commit — this is also the rollback mechanism):
   `powershell -ExecutionPolicy Bypass -File adopt.ps1 -Ref <branch|tag|commit>`
4. **Admin PC only:** `publish.ps1 -Ref <ref>` promotes a reviewed version into `main`.
5. When asked "what changed on this PC" or "what versions exist", consult `machines/*/log.md`, `git log --all --oneline`, and the machine branches on origin.
