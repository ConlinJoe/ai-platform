---
name: video-production
description: Use when a developer asks for a video, advertisement, hero film, announcement, social cut, or video studio. Optional harness capability for local code-rendered video in an existing project or a standalone studio. Silent local renders do not spend Scenario credits. Paid image, video, and audio generation require a named provider, a price, and explicit authorization.
---

# Video production

One optional capability covers both modes. The renderer is the harness
film stage (`templates/video/runtime/`). Do not maintain a second
renderer, and do not copy the Scenario Kinetic Film package into this
repository.

Read `docs/contracts/features/video-production.md` in the AI Platform
clone before installing or rendering. This skill is the procedure.
The contract is the decision.

## When this applies

Use this skill when the developer asks for a video, an advertisement, a
site hero film, a product announcement, a social cut, or a video studio.

Do not route that request through Impeccable or Hallmark. Those skills
remain the design stack for interface and art direction. A website
redesign still follows `40-ui` and its comp gate. A video does not
reopen that gate, and a video approval does not approve a website.

Offer the capability. Do not install it until the developer asks.

## Modes

Mode A, an existing application:

```bash
"$AI_PLATFORM/scripts/install-video-production.sh" /path/to/project
```

Mode B, a new video-only studio:

```bash
"$AI_PLATFORM/scripts/init-video-studio.sh" /path/to/video-studio
```

Both modes then use:

```bash
"$AI_PLATFORM/scripts/video-new-campaign.sh" /path/to/project <slug> <template>
"$AI_PLATFORM/scripts/video-render.sh" /path/to/project/video/campaigns/<slug>
```

Templates: `ad-15`, `ad-15-vertical`, `hero`, `announcement`, `identity`.
`smoke` is a synthetic pipeline check, not a client template.

`--format landscape|vertical|square|social` sets the stage size.
`landscape` is 1920x1080. `vertical` is 1080x1920 and is composed for
that frame. Do not place a landscape film inside black bars and call
it vertical.

## Before any pictures move

Inspect the project the campaign belongs to. For Mode A, read its
contracts, brand, type, tokens, photography, approved marketing copy,
product facts, and compliance limits. If an approved creative direction
already exists, use it. Do not ask the developer to pick it again.

Write a short brief in the campaign: purpose, audience, platform,
duration, aspect, brand, message, call to action, assets, motion, and
audio. Ask only when a material choice is still open.

Do not invent claims, testimonials, customers, architectural features,
or product capabilities. On-screen words come from approved project
copy or from text the developer supplies for this film.

Each campaign has its own `brand.md` and `assets/`. Do not point one
campaign at another campaign's logo, type, colors, or photographs.

## Edit the source, then render

The editable film is `film/spec.js` (words, timing, palette, format)
and, when the shared stage is not enough, `film/motion.js` or
`film/film.js`. A finished MP4 is not the source.

Preview in a browser:

```bash
python3 -m http.server --directory video/campaigns/<slug> 5671
```

Open `http://127.0.0.1:5671/film/`. Space plays. Arrow keys step one
frame. That preview is local. It is not publication.

Render:

```bash
"$AI_PLATFORM/scripts/video-render.sh" video/campaigns/<slug>
```

The command prints `Local render. No Scenario credits.` It writes a
master, a smaller review file, stills, a contact sheet, and
`renders/technical-report.json`. It refuses to replace an existing
master unless `--replace` is present. It does not delete review files
on its own.

`--resolution 4k` is optional. The default is 1920x1080 (or the
campaign's own stage, at 1x). 4K is refused when the machine reports
less than 12 GB of memory. The renderer uses one Chrome worker.

Rendering may launch headless Chrome only against this campaign's local
film page. That authorization does not cover application browser QA,
and application browser QA does not cover video rendering.

## Motion

Choose motion from the brand and the audience. Restrained and
expressive treatments are both valid. The shared stage provides masked
type, word stagger, a side wipe, a slat-edged wipe, a slow hero scale,
and an identity rule. Prefer those, or campaign-specific code, over a
generic effect preset.

Do not import the aggressive motion of the Kinetic Film demonstration
as a house style. Do not add particles, flashes, or camera shake unless
the brief asks for them. A calm film is allowed to hold.

Photographs use `object-fit: cover` or a logo uses `object-fit: contain`
with one dimension set from the file's own ratio. Do not stretch a logo
or a source image to the frame.

## Audio

Silent delivery is complete. Add audio only from a track the developer
has the right to use, or from a paid generation they authorize. Do not
copy commercial music or imitate a copyrighted recording.

## Paid generation

Local rendering does not spend Scenario credits. It still uses the
developer machine and the agent model.

Image, video, or audio generation through Scenario or any other
provider is a separate action. Before any chargeable call:

1. Name the provider and the model.
2. Verify the price with a dry run. Do not guess a missing price.
3. Describe the file that would be created.
4. Wait for explicit authorization.
5. Stay inside the approved budget.
6. Do not automatically spend credits on a retry.

`video-render.sh` rejects paid flags. Do not route around that.

Do not upload confidential or unapproved media to a provider.

Permission to render locally is not permission to publish, upload,
deploy, or spend credits.

## Review

A normal film goes: brief, timing, local preview, watch the motion,
revise the spec, render the master, read the technical report, inspect
the stills and the review file. Do not add an approval gate for a small
timing change. Do not treat a successful encode as design approval.

Technical failures and creative notes are separate. The validator fails
a file for duration, frame count, dimensions, frame rate, codec, color
metadata, audio configuration, decode errors, or a completely blank
picture. Holds, crop suspicions, and possible flashes are notes. A calm
architectural film must not fail because it moves less than a trailer.

## What this skill does not do

It does not install itself during ordinary bootstrap. It does not add
Playwright to the application `package.json`. It does not change
Deployer, Impeccable, Hallmark, or the website comp gate. It does not
vendor Scenario Kinetic Film. Developers who already hold that package
may keep using it on their own machine. That package is not a second
harness renderer, and its files do not belong in this repository.
