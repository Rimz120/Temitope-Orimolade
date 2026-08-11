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

## Standing rule: market-hours gating

Before scanning for or proposing any intraday/technical setup (bucket 2
Mag7 momentum entries, bucket 3 SPX daily setups), verify the market is
currently in regular session: **9:30 AM–4:00 PM ET, Monday–Friday**,
excluding NYSE holidays and adjusted for early-close days (e.g. the day
after Thanksgiving, Christmas/July 4th eves).

- Check the current time in ET against that window before pulling
  intraday technicals (opening range, VWAP, 1-min/4h confirmation,
  live 0DTE OI) — these reads are meaningless or stale outside the
  session.
- If asked to scan while the market is closed, say so plainly and don't
  fabricate a live technical read. Offer instead to prep a watchlist/plan
  for the next session's open, or to run it once the market opens.
- Bucket 1 (long-term energy/AI infrastructure research) is **not**
  time-gated — fundamentals research, screening, and thesis-building can
  happen anytime.

## Standing rule: automated background scanning

A local cron job runs `scripts/scan_and_alert.sh` every 5 minutes on the
machine where the `robinhood-trading` MCP server is registered, invoking a
headless `claude -p` session to scan bucket 2 (Mag7 momentum) and bucket 3
(SPX daily) during market hours only — self-gated in America/New_York
time so it doesn't drift across DST changes.

- **Alert-only.** A normal run finds nothing, logs `NO_SETUP` locally, and
  sends no notification. A push alert (ntfy.sh) fires only when a setup
  fully qualifies under that bucket's existing entry-discipline and risk
  rules.
- **Read-only by construction, not just instruction.** The headless
  invocation is locked to an explicit tool allowlist (`WebFetch`,
  `WebSearch`, and read-only `robinhood-trading` tools only). No
  order-placement/modify/cancel tool is ever on that allowlist, so this
  path cannot place a trade regardless of what the model outputs — a
  second, CLI-enforced layer under "screen & suggest only" below, not a
  replacement for it.
- **Execution still requires the interactive session.** A qualifying
  alert means "come review this," never a placed or pending order. Acting
  on an alert still goes through every standing rule below unchanged:
  per-trade approval, market-hours gating, execution/account constraints.
- Setup notes (ntfy topic, tool allowlist, cron entry) live as comments in
  `scripts/scan_and_alert.sh`.

## Standing rule: execution & account constraints

- Only accounts explicitly flagged `agentic_allowed=true` can have orders
  placed by this agent. All other linked accounts (IRAs, other individual/
  margin accounts) require the user to place the order manually — screen
  and propose for those accounts the same as any other, but say so
  plainly rather than attempting a call that will fail.
- The Robinhood agentic MCP connection supports **single-leg orders
  only** — long call, long put, covered call, cash-secured put. Multi-leg
  spreads cannot be placed through this agent regardless of account
  option level; they must be entered manually in the Robinhood app.
- Spread trading (option level 3) is **not available on Robinhood IRAs**
  at all, even for manual entry — a platform restriction, not a
  suitability gate. Cash-secured puts (level 2, full collateral) remain
  available in IRAs and are the practical route to genuinely high-POP
  structures there.
- A cash-secured put's collateral requirement is strike × 100 regardless
  of how far OTM the strike is — check this against actual account
  buying power (not total value; unsettled proceeds don't count) before
  proposing size.

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
- First touch only (added 2026-08-10): a level's edge is highest on its
  first test of the session — once price has already tested and held a
  level, treat later touches of that same level as lower-probability

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
- Forced flat time (added 2026-08-10): stop monitoring/trading positions
  by a fixed time early in the session (e.g. ~11:15 AM ET / 8:15 AM PT)
  regardless of open P&L — a discipline backstop alongside the daily loss
  limit, independent of whether that limit has been hit

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

#### POP calibration note (2026-07-10)

An 80%+ POP bar for single-leg 0DTE structures proved unreachable in
practice — defined-risk spreads can clear that on SPX, but this agent's
execution path (see execution constraints above) only supports single-leg
orders, which cap out far lower. Recalibrated screening threshold to
**30%+ POP** for single-leg 0DTE proposals; reserve an 80%+ bar for
defined-risk spread proposals when the account has Level 3 approval and
the capital to support the wider collateral requirement.

## Options structure playbooks

These structures cut across buckets 1 and 2 above — they're how a thesis
gets expressed, not a thesis on their own. See "Standing rule: execution
& account constraints" above for what's actually placeable where.

### Cash-secured puts (CSP) — income/premium-selling

Sell an OTM put, collateralized in full (no margin needed, so this works
in IRAs without spread approval).

POP and yield trade off directly against each other on any single
strike — moving the strike closer to spot buys yield and costs
probability, one-for-one. No ticker breaks that relationship; it's priced
consistently by the market, not a screening gap.

High-IV small-caps (e.g. OKLO, NNE) pay more premium than liquid low-IV
names (e.g. SOFI, RIVN) at matched POP. That extra yield compensates for
two distinct things, not one: worse execution quality (thin open
interest, wide bid/ask spreads) *and* genuine fundamental uncertainty
(pre-revenue, single-name concentration, real terminal-value risk) — both
matter, treat neither as free money.

Screen on, in order: POP target → strike/collateral fit against actual
buying power → open interest and spread width as a hard liquidity filter,
not an afterthought.

### LEAP calls (12+ months) — directional conviction

Buying a long-dated call has a hard POP ceiling around **43-45%**,
confirmed by testing delta up to 0.98 (52%+ in the money) across multiple
durations (11-18 months) — going deeper ITM or longer-dated does not move
this. A deep-ITM LEAP call converges toward synthetic stock ownership,
and the platform's POP model prices that under risk-neutral (not bullish)
drift, capping POP well below what delta alone suggests. 70%+ POP does
not exist on a purchased call, on any name, at any strike or cost — don't
screen for it.

Since POP tops out well short of "high probability," judge these as
leveraged directional bets instead: best-available POP + liquidity +
leverage, in service of an actual thesis (bucket 1 or bucket 2 above).

The POP ceiling is driven by **implied volatility, not by which bucket
the name is in** — lower IV means less extrinsic-value drag on the
breakeven at the same depth-in-the-money, so it's worth checking IV
directly rather than assuming Mag7 beats energy/AI-infra (or vice versa)
as a category. On 2026-07-10, Mag7 names as a group did screen better
(IV ~30-53% vs. energy/infra's ~50-124%), but a high-IV Mag7 name (TSLA,
the group's outlier) landed closer to the energy/infra cluster than to
AAPL — confirming it's the IV level driving the result, not the bucket
label.
