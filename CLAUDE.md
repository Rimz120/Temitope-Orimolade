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

#### Method 1: Opening range breakout

Entry:
- Mark the opening range from the first 30 minutes (9:30–10:00 ET) high/low.
- Wait for a volume-confirmed break (volume above the recent average) of
  the OR high or low — never in the first 5 minutes after the open (see
  risk rules above).
- Direction bias must agree with the 9/21 EMA (price above both EMAs for
  a long break, below both for a short break).

Confirmation:
- Stronger read when the OR break also clears a prior-day or overnight
  high/low — a fresh-session break that's also breaching a known
  reaction zone carries more weight than an OR break in isolation.

Invalidation:
- A close back inside the opening range, or rejection at the
  prior-day/overnight level being tested.

#### Method 2: VWAP trend/range read

Entry:
- Classify the session first: a trend day holds one side of VWAP all
  session; a range day oscillates around it.
- Trend day: enter on a pullback to VWAP in the direction of the held
  side.
- Range day: fade extremes back toward VWAP, only when paired with RSI
  divergence at that extreme (RSI divergence alone, without a level, is
  not a signal).

Confirmation / target:
- Target the nearest volume-profile high-volume node (support/resistance)
  or a heavy-OI strike from the session-structure gamma read —
  low-volume gaps between spot and that target suggest a fast move
  rather than a grind.

Invalidation:
- Trend-day pullback trade: a VWAP reclaim against the position (losing
  the held side).
- Range-day fade: a break beyond the extreme being faded, invalidating
  the range read.

#### Method 3: Multi-timeframe confirmation (validated 2026-07-10)

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

#### Method 4: Heatmap / king node (SpotGamma GEX, standalone, unvalidated)

A second, independent SPX signal — not a confirmation layer on Method 3
above. Trades the pull toward the dominant gamma-exposure strike
directly, rather than trend/momentum structure. Still subject to the
standing market-hours gating rule before treating a read as live.

Data: **SpotGamma's GEX heatmap** (strike × expiration grid of signed
dollar gamma exposure). No API access to this account — read it
manually from what the user shares (screenshot or verbal readout) each
time this method is scanned. There is no live feed behind this: treat
every read as a snapshot valid only as of when it was captured, and
re-request an updated heatmap before acting if meaningful time has
passed or spot has moved materially since the last one. If no current
heatmap has been shared, stand this method down rather than reasoning
from a stale or remembered read.

Scope: unlike Methods 1-3, this method is **not** restricted to 0DTE —
read the full visible board across all near-dated expirations (SpotGamma
typically shows the next several sessions), not just today's column.

Definitions:
- **King node**: the strike/expiration cell with the single largest-
  magnitude signed $ GEX on the visible board. SpotGamma often flags
  this visually (highlight/star, as in the 08-14 7675 example) — treat
  that flag as authoritative when present rather than re-deriving it by
  eye.
- **Node dominance**: candidate cell's $ GEX magnitude ÷ next-largest
  same-side cell's magnitude (any expiration). Require ≥1.5x to call a
  strike "qualifying" — a flat board on a given side has no reliable
  magnet on that side.
- **King node (per side)**: the qualifying node above spot and the
  qualifying node below spot, independently — each can sit on a
  different expiration date. If a side has no qualifying node, that
  side contributes no bias.
- **Flip zone**: the region between the two king nodes (above and below
  spot), when both exist. Directional bias is toward the node with
  materially greater $ GEX magnitude; when two candidates are close in
  magnitude, prefer the nearer-dated one — pin strength concentrates
  faster as an expiration approaches its own close. If only one side has
  a qualifying node, bias defaults toward it; if neither does, stand
  down.

Entry rules:
- Only trade when spot sits inside the flip zone (price hasn't already
  traded through the king node being targeted) and that side clears
  ≥1.5x node dominance.
- Bias direction = toward the king node; scale size down the further out
  it sits in price — a pull toward a node >1.5% away is a
  lower-confidence read than a wall 0.3% away, regardless of its $ GEX
  size.
- The final-90-minutes urgency boost only applies to a node whose own
  expiration is **today** — that's when gamma pinning concentrates into
  a close. A node dated a few sessions out runs on its own timeline and
  doesn't get today's late-session boost just because it's the largest
  number on the board right now.
- Predefine invalidation before entry: a close through the king node on
  volume. Since there's no live feed, also invalidate the read itself —
  don't hold a bias from an old screenshot once a fresh heatmap is
  available; re-anchor on the new one rather than assuming continuity.

Caveats:
- This is a manual, screenshot-driven method, not an automated pull —
  its reliability depends entirely on how current the shared heatmap is.
  I can't independently refresh or verify it mid-session.
- SpotGamma's $ GEX is real signed dealer gamma exposure, not raw OI —
  meaningfully stronger signal than the Robinhood OI data this method
  was originally speced against (superseded).
- Unlike Method 3 (validated 2026-07-10), this method has no live track
  record yet. Mark trades taken under it as such and don't upgrade its
  POP/confidence framing until it's actually proven in session.

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
