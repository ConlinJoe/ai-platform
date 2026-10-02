# UI comp approval

Use this for a major page or screen redesign, a new or reworked
multi-step flow, or a substantial responsive refactor.

Do not use it for small polish, copy changes, straightforward fixes,
or a local addition that keeps the established screen.

Canonical rule: `.cursor/rules/40-ui.mdc`, section **Substantial
redesign**. That rule wins if this checklist and the rule disagree.
Skill routing, project design authority, and `shape` / `new-work`
integration live there. Decision: `docs/contracts/adrs/0008-substantial-redesign-comp-approval.md`.

## Checklist

1. Inspect the current product, design system, content, and behavior,
   including the states the flow actually has.
2. Build one static review page of the key screens and the states that
   matter. Show each at a phone width and a desktop width, labeled, on
   the same page. Include keyboard-open, selected, empty, error, and
   result states when the flow has them. Keyboard-open means the mobile
   layout while the on-screen keyboard is visible and the active field
   is still reachable.
3. Save the page and its relative assets at
   `design-reviews/<slug>/index.html` in the project, unless a project
   contract already names a review-comp directory. The page must open
   from disk in a regular browser. Do not leave the only copy in an
   agent store, a chat attachment, or a temporary server.
4. Give the absolute path and a `file://` URL. Explain the proposed
   behavior and any consequential decisions.
5. Stop. Do not change application UI until the user approves that comp.

The comp is a review artifact. It is not production source. Creating it
does not authorize deployment, a dependency change, or a commit.

After approval, implement only that direction, then the existing
bounded real-browser verification and project checks from `40-ui` and
`60-browser-qa`.

An explicit user instruction to skip the comp outranks this gate. Say
that it was waived. A skill default does not.
