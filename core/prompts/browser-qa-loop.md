# Browser QA loop

Use this prompt **only** when the current task explicitly authorizes
Playwright / browser QA. Do not run this loop merely because a feature
was implemented, Playwright is installed, or a browser-QA contract exists.

Policy: `docs/contracts/features/browser-qa.md`.
Agent invocation: `.cursor/rules/60-browser-qa.mdc`. This prompt is the
**full** Mode A→B loop. A significant-UI bounded Mode B visual pass is
not this loop and does not by itself require new Mode A tests.
Laravel/Livewire extras: `core/project-profiles/laravel-webapp.md`.

If Playwright is required by this loop but its browser binary is
unavailable, do not silently install large browser dependencies and do
not report an interactive browser pass as Mode A. Use an available
real-browser capability for authorized visual/interactive checks, and
report that Playwright automation was not executed.

## Loop

1. Implement the change.
2. Run the application's automated tests (PHPUnit/Pest/etc.).
3. Run Mode A (`npm run test:e2e` or the project's equivalent).
4. Explore with Mode B using the best available real-browser
   capability. Do not merely replay Mode A. Do not report that pass as
   Playwright execution.
5. Fix defects.
6. Add Mode A coverage for meaningful defects.
7. Re-run application tests and Mode A.
8. Repeat until green.

## Mode B exploration

Behave like a real operator. Cover alternate paths that Mode A may not yet
include:

- validation correction after a failed submit
- double submission
- browser Back / history resubmission on create flows
- cancel and reopen
- state / lifecycle transitions
- empty and sparse states
- failure and retry
- rerouting or reassignment where the product has those flows
- unexpected navigation

Inspect console, network, and browser behavior. Stub or fake external
integrations. Do not drain shared development queues. Do not wipe demo data.

## Selectors

Prefer role and label. Add `data-testid` only when semantic selectors are
unreliable or a stable automation contract is needed.
