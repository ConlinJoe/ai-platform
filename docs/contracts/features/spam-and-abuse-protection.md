---
status: active
last_reviewed: 2026-10-13
source_of_truth_for:
  - Spam and abuse protection for public submission surfaces
  - What counts as protection, including server-side enforcement
  - Not-applicable recording, adoption inventory, and safe rollout
depends_on: []
referenced_by:
  - ../../../.cursor/rules/00-platform.mdc
  - ../../../.cursor/rules/20-coding.mdc
  - ../../../.cursor/rules/30-laravel.mdc
  - ../../../.cursor/rules/35-roots.mdc
  - ../../../.cursor/rules/50-workflows.mdc
  - ../../../core/agent-core.md
  - ../../../core/project-profiles/laravel-webapp.md
  - ../../../core/project-profiles/roots-radicle.md
  - ../../../core/prompts/project-adoption.md
  - ../../00-project-context.md
  - ../../README.md
  - ../../adopting-projects.md
  - ../../how-it-works.md
type: feature
---

# Spam and abuse protection

Canonical requirement for public submission surfaces on every stack.
Laravel, WordPress (including Roots/Radicle/Sage), custom APIs, and
other projects follow this contract. Stack rules, profiles, bootstrap,
and adoption checklists point here. They do not restate this policy.

`.cursor/rules/36-wordpress-theme.mdc` owns `theme.json` and Tailwind
presets. It does not define submission protection.

## Applicability

A public submission surface is any public endpoint that creates a
record, sends mail, or triggers costly work. That includes contact and
lead forms, quote requests, registration, comments, and similar APIs.

| Project | What to record |
| --- | --- |
| AI Platform repository | Not applicable. This repository has no public submission surface. |
| Any other project with no such endpoint | `not applicable` in `docs/contracts/features/public-submissions.md`, with the reason. |
| Any project with one or more | `applicable` in that same file, plus the inventory in [Project record](#project-record). |

New projects include this protection when the surface is built. It is
part of that surface, not a follow-up hardening task.

A project that never accepts public submissions stops after recording
`not applicable`.

## Requirement

For each applicable endpoint:

1. **Server-side enforcement.** Validate input, apply rate limits, and
   verify any challenge on the server before creating the record,
   sending mail, or starting costly work.
2. **Sensible rate limits.** Limit by client (IP, plus identity or
   target when the product has one) and by route. Allow ordinary human
   use. Record the chosen limits in the project contract. Do not copy
   one platform-wide number into every project.
3. **Input validation.** Use the stack's native validator for required
   fields, types, lengths, and formats.
4. **Tests.** Cover one accepted valid submission and at least one
   rejected submission. A rejected submission must not create the
   record, send the mail, or start the costly work. Cover invalid
   input. When a rate limit or server-side challenge exists, cover that
   rejection too.
5. **Secrets stay out of source control.** Document environment
   variable names and which environments need them. An env example may
   list names with empty values. Do not commit filled credentials.

A browser widget, JavaScript check, or CSRF token alone does not count as spam protection. Keep CSRF, nonces, and client checks where the stack already requires them. They do not replace the controls above.

## Stack-native protection

Use the installed stack's native protection where it meets this
requirement. Follow Current-First and Framework-Native First in
`00-platform`. Do not add a package when the stack already provides
the control.

| Stack | Prefer |
| --- | --- |
| Laravel | Validation (Form Requests or the installed equivalent) and the framework rate limiter (`throttle` / `RateLimiter`). Livewire and Blade still enforce on the server. |
| WordPress, including Roots/Radicle/Sage | The project's forms system, using its server-side validation, submission handling, and spam controls. New Roots projects prefer WPForms Lite for ordinary forms (`.cursor/rules/35-roots.mdc`). That preference is not a vendor mandate for Laravel, custom APIs, or other stacks. |
| Custom HTTP APIs and other stacks | That stack's validation and rate limiting. |

If the chosen forms system cannot enforce this requirement on the
server, extend it through a supported integration or choose another
mechanism that can. Do not hand-code a parallel POST handler when the
forms system already meets this contract. Do not fork plugin code.

## Challenges

A challenge is not required on every endpoint.

When a public lead form (contact, quote, demo request, or similar)
warrants a challenge, recommend Cloudflare Turnstile. Verify the token
on the server with Cloudflare's current siteverify API. Follow that
current documentation. Do not hard-code keys.

Do not require Turnstile, WPForms, reCAPTCHA, hCaptcha, Akismet, or
any other vendor across all projects. Another server-verified
mechanism is acceptable when it meets this contract. Native rate
limits and validation are enough when a challenge is not warranted.

The widget alone does not count.

## Rollout

Add protection without taking a live form offline by accident:

1. Put credentials in the target environment before enforcement
   depends on them.
2. Verify accepted and rejected submissions in a non-production
   environment.
3. Turn enforcement on only after that environment is configured.
4. Treat a missing, empty, or placeholder secret as a failure, not a
   pass.
5. Do not enable a required challenge on a live form before that
   environment has working server-side verification. That rejects
   every real submission.

Bootstrap does not install challenge widgets, spam plugins, form
plugins, or API keys.

Existing-project adoption inventories current endpoints and current
protection, then recommends. It must not silently retrofit, install,
enable, or deploy this control. Changing a live form requires explicit
developer approval.

## Project record

`templates/docs/contracts/features/public-submissions.md` is the
project-owned record. Bootstrap copies it into new projects and adds
it to an existing project when the file is missing. The record stores
applicability, endpoints, mechanism, rate limits, tests, environment
variable names, and rollout state. It does not restate this policy.
Do not put secret values in it.

### Recording examples

Not applicable:

```text
Applicability: not applicable
Reason: CLI only. No public endpoint creates records, sends mail, or triggers costly work.
```

Applicable, native controls only:

```text
Applicability: applicable

| Endpoint | What it does | Server-side protection | Rate limit | Tests | Environment variable names |
| POST /contact | Creates a lead and sends mail | Laravel validation and throttle | 5/minute per IP | ContactTest accepted and over-limit | (none) |

Rollout: enforced in staging; production stays on the previous behavior until an over-limit post is rejected there without sending mail.
```

If a challenge is enabled, add its secret variable name to that row.
Do not record the secret value.
