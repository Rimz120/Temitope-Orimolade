# Robinhood Trading Agent — Instructions

This repo hosts the setup and strategy for a Claude Code agent connected to
Robinhood's Agentic Trading via the `robinhood-trading` MCP server
(`https://agent.robinhood.com/mcp/trading`), registered at **user scope**
(not committed — see PR #1 discussion).

## Standing rule: screen & suggest only

The agent must **never place, modify, or cancel an order without the user's
explicit, per-trade approval**, even though Robinhood's platform permits an
agent to trade without per-trade confirmation if instructed to do so. This
repo's agent is intentionally NOT configured for autonomous execution.

For every trade idea: present the ticker, direction, thesis, and size
rationale, and wait for explicit user confirmation before calling any
order-placement tool.

## Strategy buckets

### 1. Long-term — energy/AI infrastructure bottlenecks

Thesis: companies solving physical constraints on AI buildout (the "picks
and shovels"), not the AI models themselves.

Sub-themes to screen:
- Power generation: natural gas turbines, nuclear/SMR developers, uranium
  supply chain
- Grid infrastructure: transformers, transmission equipment, grid software
- Data center power delivery: power management semiconductors, backup
  power/UPS, on-site generation
- Cooling: liquid cooling for high-density AI racks
- Utilities with disclosed hyperscaler/data-center exposure

Screening criteria:
- Rising order backlog / book-to-bill (demand outstripping supply)
- Disclosed hyperscaler relationships or contracts (Microsoft, Google,
  Amazon, Meta, Oracle, OpenAI-linked buildouts)
- Active capacity expansion capex with a defined ramp timeline
- Expanding margins (pricing power signal)
- Skip names where revenue growth isn't actually accelerating despite
  AI-adjacent narrative

### 2. Short-term — Magnificent 7 news momentum

Trade momentum only when a news catalyst AND a technical confirmation both
line up — never news alone.

Catalysts: earnings beats/guidance raises, AI capex announcements, product
launches, major partnership/contract news, analyst upgrade clusters.

Technical confirmation:
- Breakout above a clear resistance level on volume above its 20-day
  average
- Relative strength vs. the other six Mag7 names and the S&P 500 in the
  days following the catalyst (not just a one-day pop)

Entry discipline:
- Prefer the pullback/retest of the breakout level over chasing the
  initial spike
- Only take momentum longs while price is above the 20-day EMA
- Predefine an invalidation level (stop below breakout level or recent
  swing low) before proposing entry
- Flag reduced size around earnings dates due to gap risk

### 3. Daily — SPX technical setups

Highest-risk bucket; position sizing is the primary risk control.
Defined-risk structures (spreads) are preferred over naked options.

Session structure:
- Opening range (9:30–10:00 ET): mark high/low; a volume-confirmed break
  is the primary intraday trend signal
- VWAP: trend days hold one side all day; range days oscillate around it
- Prior day and overnight high/low: high-probability reaction zones
- Key options strikes / gamma levels: large open-interest strikes often
  act as magnets or resistance, especially into 0DTE expiration

Indicators:
- 9/21 EMA for intraday trend bias
- RSI divergence at range extremes, only paired with a level (not
  standalone)
- Volume profile: high-volume nodes = support/resistance, low-volume gaps
  = fast-move zones

Risk rules (hard limits, not suggestions):
- Max loss per trade and per day — no revenge trading past the daily limit
- Avoid trading the first 5 minutes after the open
- Defined-risk structures over naked options given premium decay/volatility

#### Multi-timeframe confirmation method (validated 2026-07-10)

SPX itself has no historicals endpoint via the Robinhood trading API — use
SPY as a 10x proxy and scale.

Pull three timeframes before calling a directional bias:
- **1-minute (today's session):** EMA9/21, VWAP, RSI14. Mark the opening
  range from the first 30 minutes; a volume-spike break of that range is
  the primary intraday signal.
- **4-hour (~6 months back):** EMA20/50, RSI14 — swing structure.
- **Daily (~9-12 months back):** SMA50/200, RSI14 — primary trend.

Cross-reference the 1-min target zone against live 0DTE option open
interest by strike — a heavy call (or put) OI strike above/below spot acts
as a magnet/target, sharper than eyeballing chart resistance alone.

Treat alignment across all three timeframes (price above both short and
long moving averages on every timeframe, RSI neutral-to-bullish/bearish on
each, none overbought/oversold) as higher-confidence than any single
timeframe in isolation. This read correctly called the 2026-07-10 session:
a flash break of the opening range on a volume spike, a V-shaped reclaim,
and continuation toward the 7600-strike call OI wall.
