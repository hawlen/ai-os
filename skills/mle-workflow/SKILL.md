---
name: mle-workflow
description: Production workflow for quant strategies & ML systems — data contracts, leakage/look-ahead prevention, walk-forward evaluation, reproducible pipelines, promotion gates, monitoring, and rollback. Use when building, reviewing, or hardening a backtest, strategy search, or ML pipeline beyond a one-off notebook.
metadata:
  origin: ECC, re-skinned for ARPWIZ / quant backtesting
---

# ML / Strategy Engineering Workflow

Turn model or **strategy** work into a production-grade system with clear data contracts, repeatable
training/backtests, measurable promotion gates, deployable artifacts, and monitoring. For ARPWIZ the "model"
is usually a **trading strategy / signal** and the "ML system" is the **backtest + strategy-search pipeline** —
the discipline is the same, and the failure modes are *worse* because a mistake costs real money.

## When to activate
- Planning or reviewing a strategy, signal, backtest, strategy search, classifier, or forecaster.
- Converting notebook/exploration code into a reusable backtest, evaluation, or live-signal pipeline.
- Designing promotion criteria, out-of-sample / walk-forward evals, experiment tracking, or rollback paths.
- Debugging results corrupted by **look-ahead bias, label leakage, stale data, overfit search, or train/serve skew**.
- Adding monitoring, forward-testing, or post-deploy quality checks.

## Trading & Backtest Translation
| Generic ML term | Your equivalent (ARPWIZ) |
|---|---|
| Label / target | Forward return, level hit/miss, trade outcome in R |
| Label leakage / look-ahead | Using a future bar, the signal bar's own close, repainting indicators, survivorship |
| Train/val/test split | **Walk-forward / out-of-sample** windows — never shuffle time; respect bar order + London session/tz |
| Feature point-in-time | A signal may use only data available **at the bar's close**, never later |
| Offline metric (AUC) | OOS **expectancy (R), Sharpe/Sortino, profit factor, max drawdown — all net of costs** |
| Baseline / prod model | Buy-and-hold, a random-entry sanity baseline, and your current forward-tested config |
| Promotion gate | Beats baseline OOS **and** survives spread/commission/slippage **and** respects prop-firm drawdown — else don't trade |
| Drift | Regime change (volatility/session/instrument): an edge can simply die |
| Rollback | Revert to last forward-tested config; paper-only until re-validated |

The deadliest failure is the **fake edge** — great in-sample, born of leakage / overfitting / testing-on-train.
Treat every positive backtest as **presumed false** until it survives out-of-sample + costs + an adversarial
pass. That is exactly what `council-loop` enforces.

## Pair with your tools
- `council-loop` — build-and-verify spine: no "real edge" without executed, reproduced, attacked evidence.
- `mle-reviewer` (agent) — adversarial review for leakage / look-ahead / eval mistakes.
- `silent-failure-hunter` (agent) — no fetch / fill / PnL path may fail quietly.
- `python-testing-patterns` — test feature transforms, split logic, and metric math before trusting them.
- `latency-critical-systems` / `python-performance-optimization` — fast strategy search + live data path.
- `data-engineer` (agent) — Alpaca fetch, bar store, dataset snapshots.

## Iteration Compact
Before touching strategy code, compress the work into one reviewable artifact (fits a PR description, precise
enough that someone can challenge the tradeoffs):
```text
Goal / thesis:
Decision owner (human): Alec
Instrument(s) & timeframe(s):
What action the signal changes (entry/exit/size):
Success metric (OOS, net of costs):
Guardrail metrics (max DD, prop-firm rules):
Mistake budget / unacceptable losses:
Assumptions:
Constraints (paper-only? session? news filter?):
Data snapshot (source, range, tz):
Baseline to beat:
Candidate signal(s):
Parameter plan (and how you'll avoid overfitting the search):
Eval slices (regime, session, instrument):
Known risks (leakage? overfit? costs?):
Next experiment:
Rollback / fallback:
```

## Decision Brain (for ambiguous, high-impact work)
1. Start from the **decision/trade**, not the model. Name the action the signal changes.
2. Name the cost of each error: a false entry (loss + fees) and a missed move (opportunity) are not equal.
3. Convert ambiguity into **falsifiable hypotheses**: what would separate winners from losers, and what evidence would disprove it?
4. Check prior art / a known baseline before inventing a bespoke system.
5. Score choices with (probability, confidence) × (cost, severity, impact).
6. Consider adversarial reality: regime shift, slippage, spread widening on news, and your own search overfitting.
7. Prefer the **simplest** change that reduces the most important mistake. Simplicity minimizes blunders and keeps iteration fast.
8. Record the decision, evidence, counter-argument, and next reversible step (the `council-loop` ledger).

## Metric & Cost Economics
Choose metrics from failure costs, not habit:
- **Expectancy (R per trade)** and **profit factor** are primary — they tie directly to PnL.
- **Max drawdown** and **prop-firm daily/total drawdown** are hard guardrails: an edge that breaches them is unusable regardless of return.
- Sharpe/Sortino for risk-adjusted comparison across strategies.
- **Always net of costs.** Report gross vs net (spread + commission + realistic slippage). If the cost haircut eats most of the edge, there is no edge.
- Compare against buy-and-hold and a random-entry baseline before celebrating.
- Treat live/forward results as **delayed, biased labels** — lag and tiny samples; don't overreact to a handful of trades.

Every metric should state which mistake it makes cheaper, which it makes more likely, and that the human owns the risk-appetite call.

## Data & Signal Hypotheses
Signals come from a theory of separation, and every one is a leakage suspect:
- For each candidate feature, state **why** it should separate outcomes and **how it could peek at the future**.
- Indicators that repaint, or any value using the signal bar's close/after, are look-ahead — gate them to the *next* bar.
- Decide how gaps are handled (weekend gaps, halts) — absence may be informative or a reason to skip.
- For outliers (news spikes), decide: clip, exclude, or treat as the signal itself.
- Beware **overfitting the search**: the more configs you try, the more false winners appear — count every config tried and correct for it in the ledger.

Do not add complexity until error analysis shows the baseline failing for a reason more signal/capacity can plausibly fix.

## Error Analysis Loop
After each backtest, parameter change, or forward-test window:
1. Split outcomes: winners, losers, scratched, missed entries, system/data failures.
2. Cluster by shared traits: instrument, session, regime (vol), time, news proximity, data gaps, parameter set.
3. Separate strategy mistakes from **data bugs, look-ahead, ignored costs, and execution/fill mismatches**.
4. Trace each cluster to one move: better data, better signal, better threshold/parameters, or better risk/exit rule.
5. Preserve every important failure as a **regression test or eval slice** — a leakage you fixed must never silently return.
6. Write the next iteration as a falsifiable experiment, not "improve the strategy."

## Observation Ledger
Keep a compact, append-only evidence trail beside the code/PR/experiment (this IS the `council-loop` ledger):
```text
Iteration:
Change:
Why it mattered:
OOS metric movement (net of costs):
Slice movement (regime/session):
Winners / losers / surprises:
Decision:
Tradeoff accepted (human):
Lesson captured:
Regression/eval added:
Next iteration:
```
Killed attempts stay logged, never deleted — that's how you honestly correct for how many configs you tried.

## Core Workflow
### 1. Define the trade / prediction contract
Target, decision owner (Alec), instrument/timeframe, entry/exit/size action, allowed latency, fallback when
data is missing, and the human approval/override path for anything live. Never accept "improve the strategy" —
tie it to an observable behavior and a measurable gate.

### 2. Lock the data contract
Instrument & timeframe grain; bar timestamp, timezone (London) and session boundaries; exactly what data is
available **at the signal bar's close**; train/OOS/walk-forward split policy; required columns, allowed gaps,
ranges; dataset version/snapshot for reproducibility. **Guard leakage first**: any value not available at
prediction time is removed or moved to an analysis-only path.

### 3. Build a reproducible pipeline
Another run (or another person) must reproduce the backtest with no hidden notebook state: typed config /
dataclasses for all params and paths; pinned deps; fixed seeds; record dataset version, code SHA, config hash,
metrics, and artifact path; use the **same** transform code for backtest and live signal; make every step idempotent.
```python
import hashlib
from dataclasses import dataclass
from pathlib import Path

@dataclass(frozen=True)
class RunConfig:
    dataset_uri: str        # e.g. Alpaca 1m bars, snapshot id
    out_dir: Path
    seed: int
    params: tuple           # frozen strategy parameters

def run_id(cfg: RunConfig, code_sha: str) -> str:
    key = f"{cfg.dataset_uri}:{cfg.seed}:{cfg.params}"
    return f"{code_sha[:12]}-{hashlib.sha256(key.encode()).hexdigest()[:12]}"
```

### 4. Evaluate before promotion
Declare promotion gates **before** the out-of-sample run, and fail closed:
```python
# Declared BEFORE the OOS run. Every metric is net of costs.
PROMOTION_GATES = {
    "oos_expectancy_R":  ("min", 0.10),   # > 0.1R per trade, out-of-sample
    "oos_profit_factor": ("min", 1.30),
    "oos_max_drawdown":  ("max", 0.10),   # within prop-firm max drawdown
    "cost_haircut_keep": ("min", 0.60),   # net edge keeps >= 60% of gross after costs
    "n_oos_trades":      ("min", 100),    # enough samples to mean anything
}

def assert_promotion_ready(metrics: dict[str, float]) -> None:
    missing = sorted(g for g in PROMOTION_GATES if g not in metrics)
    if missing:
        raise ValueError(f"missing required gates: {missing}")
    failures = {
        name: metrics[name]
        for name, (direction, thr) in PROMOTION_GATES.items()
        if (direction == "min" and metrics[name] < thr)
        or (direction == "max" and metrics[name] > thr)
    }
    if failures:
        raise ValueError(f"failed promotion gates: {failures}")
```
Offline gates are necessary, not sufficient: when it changes real behavior, **forward-test / paper** before any live size.

### 5. Package for live signal / serving
Production-ready only when the contract is testable: config + parameters + data reference versioned together;
input validation rejects stale/out-of-range bars; the live path has a timeout and a fallback; the **same**
feature/transform code as the backtest (prove equivalence with a test); decision logs carry config version and
enough to reconstruct each signal. Never let backtest feature code diverge from live without an equivalence test.

### 6. Operate
Monitor both system and edge: data freshness/gaps, fill/slippage vs assumption, **realized expectancy vs
backtest**, drawdown vs prop-firm limits, regime indicators. Every change has a rollback that names the previous
config/artifact and the switch mechanism — and stays paper-only until re-validated.

## Review checklist
- [ ] Trade/prediction contract explicit and testable; human owns the call
- [ ] Data contract: instrument/timeframe grain, bar timing, tz/session, snapshot/version
- [ ] **Leakage / look-ahead checked against bar-close availability**
- [ ] Split is walk-forward / OOS — time never shuffled
- [ ] Backtest reproducible from code SHA + config + data version + seed
- [ ] Metrics net of costs; compared to baseline; enough OOS trades
- [ ] Promotion gates automated and fail closed; respect prop-firm drawdown
- [ ] Search overfitting acknowledged and corrected (count every config tried)
- [ ] Backtest and live transforms shared or equivalence-tested
- [ ] Live path validates inputs, has timeout/fallback/rollback; paper-first
- [ ] Monitoring covers data, fills/slippage, realized edge, and drawdown

## Anti-patterns
- Notebook state required to reproduce the backtest
- Shuffled or random split leaks future bars into the test
- Signal uses the bar's own close or a future bar (look-ahead / repaint)
- Costs ignored; gross edge celebrated while net edge is negative
- Parameters tuned on the test set repeatedly (overfitting the search)
- Backtest feature code copied by hand into the live signal
- "Edge" reported from 20 trades
- Monitoring checks uptime but not realized expectancy or drawdown
- Rollback requires a re-run instead of switching to a known-good config

## Output expectations
Return concrete artifacts: data contract, promotion gates, pipeline steps, test plan, eval/forward-test plan,
or review findings. Call out unknowns that block production readiness instead of filling them with assumptions —
and flag anything that needs the human's risk-appetite decision.
