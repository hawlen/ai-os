---
name: llm-trading-agent-security
description: Security & safety patterns for automated / AI-assisted trading agents with broker order authority — for prop-firm (FTMO/Vantage) and broker accounts. Covers feed/prompt injection, risk & size limits, pre-trade validation, prop-firm rule guards, circuit breakers, human-in-the-loop approval, and credential isolation.
metadata:
  origin: ECC direct-port, re-skinned for ARPWIZ / prop-firm trading
version: "2.0.0"
---

# Trading Agent Security (prop-firm / broker edition)

An automated or AI-assisted trading agent has a harsher threat model than a normal app: a bad signal, an
injected instruction, or an unchecked order path turns directly into **lost capital or a blown prop-firm
account**. ARPWIZ is human-in-the-loop and paper-first by default — these controls keep it that way and make
any move toward live deliberate and bounded.

## When to use
- An agent or ARPWIZ module that can place, modify, or close orders via a broker API (MT4/MT5, Alpaca, bridge).
- Letting an LLM read market data / news / social feeds and turn them into trade signals.
- Designing how broker / prop-firm credentials are stored and scoped.
- Hardening anything that could breach an **FTMO / Vantage rule** (daily loss, max drawdown) — a breach fails
  the account.

## Principle: layer independent controls
No single check is enough. Each guard below must pass independently, and none of them trust the model's output:
input hygiene → risk & rule limits → pre-trade validation → human approval → execution caps → credential
isolation → audit log. A failure in any layer blocks the order.

## Examples

### 1. Treat injected market / news / social text as an attack
Anything an LLM reads can carry an instruction. Never feed raw headlines, posts, or broker messages into an
execution-capable prompt without sanitizing — and treat the feed as data to *analyze*, never instructions to *obey*.
```python
import re
INJECTION_PATTERNS = [
    r'ignore (previous|all) instructions',
    r'new (task|directive|instruction)',
    r'system prompt',
    r'(buy|sell|close|risk)\s+.{0,40}(all|max|everything|full size)',
    r'disable\s+.{0,30}(limit|stop|guard|circuit)',
]
def sanitize_feed(text: str) -> str:
    for p in INJECTION_PATTERNS:
        if re.search(p, text, re.IGNORECASE):
            raise ValueError(f"Possible injection in feed: {text[:120]}")
    return text
```

### 2. Risk & size limits (independent of model output)
Size every order from account equity and a fixed risk fraction — not from whatever the model "wants".
```python
from decimal import Decimal

MAX_RISK_PER_TRADE = Decimal("0.005")   # 0.5% of equity, measured to the stop
MAX_OPEN_POSITIONS = 3
MAX_DAILY_TRADES   = 10

class RiskLimitError(Exception): ...

class RiskGuard:
    def position_size(self, equity: Decimal, entry: Decimal, stop: Decimal) -> Decimal:
        if stop == entry:
            raise RiskLimitError("stop == entry: undefined risk")
        return (equity * MAX_RISK_PER_TRADE) / abs(entry - stop)

    def check(self, open_positions: int, trades_today: int) -> None:
        if open_positions >= MAX_OPEN_POSITIONS:
            raise RiskLimitError("max open positions reached")
        if trades_today >= MAX_DAILY_TRADES:
            raise RiskLimitError("max daily trades reached")
```

### 3. Guard the prop-firm rules (FTMO / Vantage) — breach = fail
The hard limits are the firm's, not yours. Pre-check every order against them and halt **before** a breach,
with a buffer — slippage and open positions can carry you past the line.
```python
from decimal import Decimal
# Example thresholds — set per challenge/account from the firm's actual rules.
RULES = {"daily_loss_pct": Decimal("0.05"), "max_drawdown_pct": Decimal("0.10")}
BUFFER = Decimal("0.8")   # act at 80% of the limit, never at it

class PropRuleBreach(Exception): ...

def assert_within_prop_rules(start_of_day_equity, equity, peak_equity, rules=RULES):
    daily_dd = (start_of_day_equity - equity) / start_of_day_equity
    total_dd = (peak_equity - equity) / peak_equity
    if daily_dd >= rules["daily_loss_pct"] * BUFFER:
        raise PropRuleBreach(f"approaching daily loss limit: {daily_dd:.2%}")
    if total_dd >= rules["max_drawdown_pct"] * BUFFER:
        raise PropRuleBreach(f"approaching max drawdown: {total_dd:.2%}")
```

### 4. Validate / dry-run before sending
Validate against live account state before the order reaches the broker. Paper-first is the default;
live requires an explicit flag.
```python
class OrderRejected(Exception): ...

def validate_order(order, account, *, max_spread_pts, max_gross_leverage, live: bool = False):
    if order.size <= 0:               raise OrderRejected("non-positive size")
    if order.stop is None:            raise OrderRejected("order has no stop loss")   # never send stop-less
    if account.spread_points > max_spread_pts:
        raise OrderRejected(f"spread {account.spread_points} > {max_spread_pts} (news/illiquid?)")
    if order.notional > account.equity * max_gross_leverage:
        raise OrderRejected("exceeds gross leverage cap")
    return "LIVE" if live else "PAPER"   # default path records but does NOT transmit
```

### 5. Circuit breaker (losing streak / drawdown / bad state)
```python
from decimal import Decimal
class CircuitBreaker:
    MAX_CONSECUTIVE_LOSSES = 3
    MAX_HOURLY_LOSS_PCT = Decimal("0.02")
    def check(self, consecutive_losses, hour_start_equity, equity):
        if consecutive_losses >= self.MAX_CONSECUTIVE_LOSSES:
            self.halt("consecutive losses")
        if hour_start_equity <= 0:
            self.halt("invalid hour_start_equity"); return
        hourly = (equity - hour_start_equity) / hour_start_equity
        if hourly < -self.MAX_HOURLY_LOSS_PCT:
            self.halt(f"hourly PnL {hourly:.1%} below threshold")
```

### 6. Human-in-the-loop approval (ARPWIZ default)
Per the man-machine-fusion design, live orders pause for the trader: the agent proposes, Alec disposes.
```python
def require_approval(order, *, autonomous: bool = False) -> bool:
    if autonomous:                         # OFF by default; only for explicitly-sanctioned paper runs
        return True
    return prompt_trader_approval(order)    # blocks for a human yes/no; logs the decision either way
```

### 7. Credential isolation
```python
import os
data_key = os.environ.get("ALPACA_DATA_KEY")   # READ-ONLY market data
exec_key = os.environ.get("BROKER_EXEC_KEY")    # order authority — a DEDICATED sub/challenge account
if not exec_key:
    raise EnvironmentError("BROKER_EXEC_KEY not set")   # never hardcode; never log
```
Separate the read-only data key from the execution key. Point execution at a dedicated challenge/sub-account,
never your funded or primary account. Keys come from env or a secret manager — never code, never logs.

## Pre-deploy checklist
- [ ] External feeds (news/social/broker messages) sanitized before any LLM context
- [ ] Position size = equity × risk-fraction, independent of model output
- [ ] Every order carries a stop loss; stop-less orders are rejected
- [ ] Prop-firm daily-loss & max-drawdown rules pre-checked with a buffer; trading halts before the line
- [ ] Orders validated against live account state (spread, leverage, size) before send
- [ ] **Paper-first by default; live requires an explicit, logged flag**
- [ ] Circuit breaker halts on losing streak, hourly drawdown, or invalid state
- [ ] Human approval required for live orders unless an autonomous paper run is explicitly sanctioned
- [ ] Read-only data key separated from execution key; execution scoped to a dedicated sub-account
- [ ] Every decision (proposed / approved / rejected / sent / filled) is audit-logged — not just fills

Pairs with `council-loop` (prove each guard with executed evidence; attack it) and `silent-failure-hunter`
(no order path may fail quietly).
