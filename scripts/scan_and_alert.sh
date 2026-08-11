#!/usr/bin/env bash
# Automated background scanner for the Robinhood trading agent (bucket 2 +
# bucket 3 only). Intended to run from cron every 5 minutes on the machine
# where the `robinhood-trading` MCP server is registered (see CLAUDE.md,
# "Standing rule: automated background scanning").
#
# Alert-only: sends a push notification (ntfy.sh) only when a scan finds a
# fully qualifying setup. Every other run just logs locally and exits quiet.
#
# Read-only by construction: the headless `claude -p` invocation is locked
# to a tool allowlist below. No order-placement/modify/cancel tool is ever
# included, so this script cannot place a trade no matter what the model
# outputs -- that's enforced by the CLI, not just by the prompt.
#
# --- One-time setup ---
# 1. Set NTFY_TOPIC below to a long, hard-to-guess string (not "robinhood"
#    or your name) -- ntfy.sh topics are public to anyone who knows the
#    name unless you self-host or use a reserved topic. Subscribe to that
#    same topic in the ntfy app on your phone.
# 2. Fill in ALLOWED_TOOLS with your actual robinhood-trading MCP read-only
#    tool names (check with `claude mcp list` / inspect available tools in
#    an interactive session). Only add read-only tools (quotes, technicals,
#    option chains, positions). Never add anything that places, modifies,
#    or cancels an order.
# 3. Add to crontab (`crontab -e`):
#      */5 * * * * /full/path/to/scripts/scan_and_alert.sh
#    The script self-gates on market hours, so running it every 5 minutes
#    around the clock is fine -- it's a no-op outside 9:30-16:00 ET.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$REPO_DIR/scripts/scan.log"

NTFY_TOPIC="CHANGE-ME-to-a-long-random-topic-name"
NTFY_URL="https://ntfy.sh/${NTFY_TOPIC}"

ALLOWED_TOOLS="WebFetch,WebSearch,mcp__robinhood-trading__get_quote,mcp__robinhood-trading__get_technicals,mcp__robinhood-trading__get_option_chain,mcp__robinhood-trading__get_positions"

TS="$(date '+%Y-%m-%d %H:%M:%S %Z')"

# Market-hours gate, DST-aware -- America/New_York handles EST/EDT
# transitions automatically, so this doesn't drift twice a year the way a
# fixed UTC cron window would.
DOW=$(TZ='America/New_York' date +%u)   # 1=Mon .. 7=Sun
HHMM=$(TZ='America/New_York' date +%H%M)

if [[ "$NTFY_TOPIC" == "CHANGE-ME-to-a-long-random-topic-name" ]]; then
  echo "$TS  ABORT: set NTFY_TOPIC before running" >> "$LOG_FILE"
  exit 1
fi

if [[ "$DOW" -gt 5 ]]; then
  echo "$TS  skip (weekend)" >> "$LOG_FILE"
  exit 0
fi
if [[ "$HHMM" -lt 0930 || "$HHMM" -ge 1600 ]]; then
  echo "$TS  skip (outside 9:30-16:00 ET)" >> "$LOG_FILE"
  exit 0
fi

PROMPT="Run a read-only scan for bucket 2 (Mag7 momentum) and bucket 3 (SPX daily) setups per CLAUDE.md in this repo. Apply every entry-discipline and risk rule in those sections (opening range confirmation, EMA trend alignment, RSI paired with a level not standalone, first-touch-only, multi-timeframe alignment where applicable, POP calibration for 0DTE). Do not place, modify, or cancel any order under any circumstances -- this is an unattended run with no one available to give per-trade approval. If, and only if, you find a setup that fully qualifies under those rules, output a single block starting with the exact line ALERT_FOUND: followed by ticker, direction, thesis, size rationale, and invalidation level. If nothing qualifies, output exactly: NO_SETUP -- and nothing else."

OUTPUT="$(cd "$REPO_DIR" && claude -p "$PROMPT" --allowedTools "$ALLOWED_TOOLS" --output-format text 2>>"$LOG_FILE")" || {
  echo "$TS  scan failed, see stderr above" >> "$LOG_FILE"
  exit 1
}

if [[ "$OUTPUT" == ALERT_FOUND:* ]]; then
  echo "$TS  ALERT: $OUTPUT" >> "$LOG_FILE"
  curl -sS -H "Title: Trading setup found" -d "$OUTPUT" "$NTFY_URL" >> "$LOG_FILE" 2>&1
  echo >> "$LOG_FILE"
else
  echo "$TS  no setup" >> "$LOG_FILE"
fi
