# Lessons Learned

A log of actual trade outcomes (and near-misses — setups that were screened
but not taken, or that would have triggered a method but shouldn't have)
across all buckets and methods. This is the feedback loop that turns the
rules in `CLAUDE.md` from untested defaults into something actually
validated by results.

No entries yet — nothing has been traded under this repo's methods as of
this file's creation. Log every trade that reaches an outcome (win, loss,
or invalidated before entry) using the template below, most recent first.

## How this gets used

- Before proposing a trade under any bucket 3 method (1-4), check this file
  for prior failures on that method or that setup type — don't repeat a
  known mistake.
- After a trade resolves, add an entry here. If the entry reveals the
  method's rule itself was wrong (not just an unlucky outcome), update the
  relevant method in `CLAUDE.md` and reference the date/entry here in that
  method's caveats, the same way the POP calibration note and the
  2026-07-10 validation note already work.
- Distinguish a **bad outcome** (the rule was followed correctly and still
  lost — normal variance, not a reason to change the rule) from a **bad
  rule** (the setup never should have qualified in the first place). Only
  the latter should trigger a `CLAUDE.md` edit.

## Entry template

```
### YYYY-MM-DD — Ticker — Method N (or bucket/structure name)

- **Setup:** what triggered the entry, in terms of the method's actual
  stated criteria (not vibes)
- **Entry / exit:** price, size, structure (e.g. long call, CSP)
- **Outcome:** win/loss, $ or % — and against which risk limit if any
- **Bad outcome or bad rule?**
- **Lesson:** what specifically should change, if anything
- **CLAUDE.md updated?** yes/no — link the method + date if yes
```
