# Changelog

## 1.2.0 — 2026-08-23

Simplified the UI/UX design stack. Hallmark is the only managed design
skill. `frontend-design`, `ui-ux-pro-max`, and Superdesign were removed
from the harness.

`40-ui` now classifies UI work as small, significant, or exploration.
Hallmark loads only when that classification warrants it. Significant UI
authorizes a bounded Playwright Mode B visual pass of that UI; Mode A
workflow/regression tests remain separately authorized. Small UI does
not automatically load Hallmark or start a browser QA loop.

Significant UI is reviewed against a WCAG 2.2 AA accessibility floor and
a short rendered design-review protocol. References (screenshots, URLs,
named aesthetics) supply design language; they do not override the
current product. Framework-native implementation and an established
project design system remain authoritative.

Claude and Grok adapters expose only Hallmark. Bootstrap prunes retired
managed skills on re-run, adds `.hallmark/` to project gitignores, and
keeps Cursor, Grok Build, Codex, Claude Code, and Hermes supported.
Doctor and platform tests cover the new stack.
