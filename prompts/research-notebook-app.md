# Kickoff prompt — Research & Notebook app

**How to use:** create the new project folder, open a fresh Claude Code session with that folder as the
working directory, and paste the prompt below as your first message.

---

We're starting a brand-new **research & notebook app** from scratch in this directory — a dedicated
session just for this project. Work spec-driven and test-first; don't rush to code.

**Tooling installed on this machine (use it):**
- **spec-kit** (spec-driven development) — the `specify` CLI is global. As your FIRST action, scaffold
  this project by running in the project root:
  `specify init --here --integration claude --script ps --force`
  That creates `.specify/` + the `/speckit-*` skills. We then drive development through:
  `/speckit-constitution` → `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`,
  with `/speckit-clarify` (before plan) and `/speckit-analyze` (before implement) as quality gates.
- **superpowers** (global plugin) — use its skills throughout: **brainstorming** (before we spec),
  **writing-plans**, **test-driven-development** (RED-GREEN-REFACTOR), **systematic-debugging**,
  **verification-before-completion**, **code-review**.

**The app — my starting vision (refine it WITH me; don't assume):**
A personal, local-first **research + notebook** tool. The core loop: capture research material (notes,
web links/pages, PDFs, highlights, snippets) → organize into notebooks / topics → link ideas and
sources together → search across everything → (later) ask questions and get summaries over my OWN
corpus. Think "Obsidian × a research assistant," private and mine.

Things I still need to decide with you (ask me): target platform (web app / desktop / both), the stack,
the must-have v1 feature set, the non-negotiables (e.g. local-first, my data stays mine, offline), and
explicitly what v1 should NOT try to do.

**How I want us to work:**
1. **Brainstorm first** (superpowers) — pin the vision, the user (me), the core jobs-to-be-done, and a
   tight v1 scope. Ask me your open questions before writing anything.
2. **Constitution** (`/speckit-constitution`) — the project's principles (local-first? privacy?
   test-first? stack constraints? performance?).
3. **Spec** (`/speckit-specify`) for v1 → **clarify** → **plan** → **tasks** → **implement**,
   test-first, in small verified increments. Show me proof at each step.
4. Keep it honest and verified — never claim done without a passing test and a real check.

**Start now by:** (a) running `specify init --here …` and confirming the tooling is live, then
(b) opening the brainstorming step and asking me your first round of questions about the app.
