# AI OS Platform v1 — tech spec for the overnight build

Status: DRAFT for approval · Owner: hawlen · Spec authored: 2026-07-20
Contract rule (principles/02-workflow.md): no overnight build starts until this spec is approved.

## 1. What we're building and why

The first shippable slice of the AI OS network: a public, git-backed **template registry** plus a **visual store** — an app-store-like catalog where every template (a composition of how to run Claude Code: principles, agents, skills, hooks) is a card with screenshots, description, category badges, and a one-line adopt command. This turns the hawlen repos from "my setup" into "the first entry of a platform anyone can join, browse, and adopt from."

## 2. V1 scope and non-goals

**In scope (must exist by morning):**
- The package **manifest format** (schema + validator) — the atom every later feature consumes.
- Public registry repo **`hawlen/aios-registry`** with ≥2 seeded entries: `ai-os-template` (pinned v1.0.0) and the `ai-os` machine layer (pinned commit).
- **Store**: static site generated from the registry (card grid + per-template detail pages), published via GitHub Pages by CI on every merge.
- **Adopt flow**: a copyable one-liner per card that installs the pinned template on a Windows machine.
- **Publish flow**: documented PR path + a `publish.ps1` helper that scaffolds a valid manifest; CI validates every PR.
- Tests (Pester) for validator, generator, and adopt script; CI green.

**Non-goals for v1 (explicitly deferred):**
- The private mastermind hub (`hawlen/aios-hub`, private repo — night 2); fleet map; dashboard lenses (format sketched in §3 only); ratings backend (cards link to GitHub Discussions); full education mode (detail pages carry a "learn" section; interactive tours later); local client app integration; macOS/Linux adopt scripts (structure allows them; Windows first).

## 3. The manifest format (`manifest.json`, schema v1)

One folder per template: `registry/<slug>/manifest.json` + `screenshots/`.

```json
{
  "schemaVersion": 1,
  "slug": "ai-os-template",
  "name": "AI OS project template",
  "version": "1.0.0",
  "category": "system-template",
  "description": { "short": "≤140 chars for the card", "long": "markdown for the detail page" },
  "author": { "name": "hawlen", "github": "hawlen" },
  "source": { "repo": "https://github.com/hawlen/ai-os-template", "ref": "<pinned commit sha>", "tag": "v1.0.0" },
  "installs": ["soul", "arms", "skills", "reflexes"],
  "install": { "type": "template-clone", "verify": "scripts/verify.ps1" },
  "trust": { "executes": "scripts", "validatedBy": "ci", "validatedOn": "YYYY-MM-DD" },
  "screenshots": ["screenshots/store-card.png"],
  "learn": "markdown: what this is, who it's for, how to use it",
  "links": { "discussions": "https://github.com/hawlen/aios-registry/discussions" }
}
```

- `category` enum: `system-template | dashboard-lens | skill-pack | agent-pack | education`. (`dashboard-lens` is reserved — defined now so the schema never breaks when lenses arrive.)
- `installs` uses the body map (soul/brain/arms/hands/memory/reflexes/muscle-memory/eyes) — rendered as badges on cards.
- `source.ref` MUST be a full commit SHA. CI rejects branch names — pinned versions only.
- `install.type` enum v1: `template-clone` (gh template / git clone of pinned ref into a new project) | `machine-bootstrap` (runs the repo's own installer) | `copy` (markdown-only assets copied into `~/.claude`).
- `trust.executes`: `markdown-only | scripts` — the store shows this as a badge; `scripts` templates get a warning line in the adopt UI.

## 4. Repo layout — `hawlen/aios-registry` (public)

```
aios-registry/
  schema/manifest.schema.json        JSON Schema for §3
  registry/<slug>/manifest.json      one folder per template (+ screenshots/)
  scripts/validate.ps1               schema + pinned-ref + secret-scan checks
  scripts/publish.ps1                scaffolds a manifest interactively
  scripts/generate-store.ps1         registry/ -> site/ static HTML
  scripts/adopt.ps1                  parametrized installer (see §5)
  store/                             HTML templates + CSS assets for the generator
  tests/*.Tests.ps1                  Pester: validator, generator, adopt
  site/                              generated output (Pages artifact, git-ignored)
  .github/workflows/validate.yml     PR gate: validate all manifests + run tests
  .github/workflows/pages.yml        merge to main -> generate + deploy Pages
  README.md                          what this is, how to publish, how to adopt
```

PowerShell throughout (5.1-compatible locally, pwsh on CI runners) — consistent with the whole ecosystem and testable with Pester like the dashboard. Store pages are self-contained static HTML (no backend), matching the dashboard's proven generate-to-HTML pattern.

## 5. The adoption flow (morning demo path)

Each card shows one copyable command:

```powershell
irm https://<pages-url>/adopt/<slug>.ps1 | iex
```

The generator emits a small per-template adopt script that: (1) downloads the manifest from the store, (2) resolves the pinned SHA, (3) shows name/version/`trust.executes` and asks for confirmation, (4) executes per `install.type` (for `template-clone`: clones the pinned ref into a chosen folder, removes `.git`, prints next steps; for `machine-bootstrap`: hands off to the repo's own pinned installer), (5) runs the template's `install.verify` script if declared and prints its ACTUAL output. Adoption is refused if the SHA doesn't match the manifest.

## 6. Trust model v1

Pinned SHAs only · CI schema validation on every PR · secret patterns scan on manifests · `markdown-only` vs `runs scripts` badge on every card · confirmation prompt inside `adopt.ps1` before anything executes · curation = hawlen merges registry PRs (admin gate). Supply-chain scanner integration (Socket/Snyk, as used for skills) is a fast follow, listed on the card as "not yet scanned" until then.

## 7. Success criteria (verified with executed evidence, not assertion)

1. **Browse:** the GitHub Pages URL renders the store with ≥2 template cards (screenshot, description, category + body-map + trust badges) and per-template detail pages.
2. **Adopt (the demo):** copying the `ai-os-template` command from the card and running it on this PC creates a working project from the pinned v1.0.0 — proven by the template's own `scripts/verify.ps1` passing (output pasted into the build log).
3. **Quality gates:** all Pester suites green locally (output pasted); `validate.yml` and `pages.yml` green on GitHub.
4. **Publish path:** `publish.ps1` produces a manifest for a dummy template that passes `validate.ps1`; the PR walkthrough is in the README.

## 8. Overnight build plan (model routing per principle 00)

| Phase | Work | Model route |
|---|---|---|
| 1 | Repo scaffold, schema, README skeleton | executor (sonnet) |
| 2 | validate.ps1 + tests (TDD, red/green) | executor (sonnet) |
| 3 | generate-store.ps1 + store HTML/CSS + tests | executor (sonnet); UI pass reviewed |
| 4 | adopt.ps1 + tests (incl. refuse-on-SHA-mismatch) | executor (sonnet) |
| 5 | Seed 2 entries (pinned SHAs, screenshots, learn text) | haiku/sonnet |
| 6 | CI workflows + Pages | executor (sonnet) |
| 7 | End-to-end demo run (§7.2) + fix loop | sonnet; 3-strike breaker → architect |
| 8 | Adversarial review of adopt/trust path | code-reviewer (opus) |
| 9 | Final whole-branch review vs this spec | architect (fable) |

Evidence ledger: every phase logs its verification output to `BUILD-LOG.md` in the repo (council-loop style — no phase advances on assertion). Session model orchestrates; all bulk work dispatched down per the table.

## 9. Prerequisites (user actions, in the browser — before the build starts)

1. Create empty **public** repo `hawlen/aios-registry`.
2. Invite `neoalmasview-ai` as collaborator (this machine builds and pushes).
3. After first push: Settings → Pages → deploy from GitHub Actions (I'll say when).

## 10. Open questions (answered at approval)

- Store visual identity: reuse the dashboard's look, or a fresh identity for the store? (Default if unanswered: clean fresh identity, dark/light aware.)
- Pages URL is `https://hawlen.github.io/aios-registry/` by default — fine for v1, custom domain later?
