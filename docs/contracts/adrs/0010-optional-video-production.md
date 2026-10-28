---
status: accepted
last_reviewed: 2026-10-28
source_of_truth_for:
  - Decision to offer one optional video-production capability for existing projects and standalone studios
  - Decision to keep an original local renderer and not redistribute the Scenario Kinetic Film package
depends_on:
  - ../features/video-production.md
referenced_by:
  - ../features/video-production.md
type: adr
---

# ADR-0010: Optional video production

## Status

Accepted

## Context

Local experiments rendered branded films as web pages: a frame is a
function of time, headless Chrome captures it, and FFmpeg writes the
file. LuxTerra produced a six-second 1080p30 sample. Evolution Fence
produced a fifteen-second advertisement with its own type, photography,
and transitions. Both renders were local and did not spend Scenario
credits.

The experiments used a downloaded Scenario Kinetic Film skill. That
package is not the same work as `scenario-kinetic-music-video` in the
MIT-licensed `scenario-labs/skills` repository. The Kinetic Film zip
observed on 2026-10-28 (package dated 2026-09-26) contains no `LICENSE`
file, and its `SKILL.md` declares no license. The bundled fonts are
SIL Open Font License. That license does not cover the engine.

The harness is MIT licensed. Public download is not permission to
relicense or redistribute the engine. The harness also must not grow a
second, vendor-specific renderer, and it must not install video
tooling into every application during bootstrap.

## Decision

- Video production is one optional capability. Mode A installs it into
  an existing project. Mode B initializes a video-only studio. Both
  call the same scripts and the same stage code.
- The renderer shipped here is original. It is a small browser stage,
  a Playwright capture through the system Chrome, FFmpeg, and a
  Python validator that uses the standard library plus FFmpeg. It is
  not a port of the Kinetic Film engine.
- The Kinetic Film package is not vendored, not pinned in
  `skills-lock.json`, and not downloaded by bootstrap. A developer who
  already has that package may keep using it outside this capability.
  It is not a second harness renderer.
- Bootstrap does not prompt for video and does not install it unless
  `--with-video` is passed. `scripts/install-video-production.sh` and
  `scripts/init-video-studio.sh` are the explicit paths. Playwright
  for rendering is installed under `video/.runtime` on the first
  render, with npm scripts ignored so a browser is not downloaded.
  Application `package.json` and `composer.json` are not modified.
- Vertical video is a native stage size (1080x1920), not a padded
  landscape frame. Technical validation does not apply the Kinetic
  Film demonstration's motion minimums.
- Local rendering does not spend Scenario credits and does not
  authorize publication or paid generation. Chargeable generation
  stays behind a provider name, a dry-run price, and explicit
  authorization.
- Impeccable, Hallmark, the website comp gate, and Deployer are
  unchanged. Video frame capture is a separate authorization from
  application browser QA.

## Consequences

### Positive

- An existing project and a new studio share one workflow.
- The public repository does not gain an unlicensed engine or client
  media.
- Projects that never make video do not gain a video runtime.
- A calm film can pass technical checks.

### Negative

- The harness stage is a starting set of type, wipes, and holds. A
  campaign that needs the Kinetic Film block library has to be written
  as its own `film.js`, or the developer uses a copy of that package
  they obtained separately.
- The first render needs Node, FFmpeg, and Google Chrome. The harness
  does not download Chrome.

## Alternatives considered

- Vendor the Kinetic Film zip. Rejected. No redistribution license was
  found, and the fonts' Open Font License does not cover the code.
- Pin `scenario-kinetic-music-video` from `scenario-labs/skills`.
  Rejected. That skill is a different product (lyric video and
  generated footage). Its MIT license does not license the Kinetic
  Film engine, and adopting it would add a second system.
- Make video part of ordinary bootstrap. Rejected. Capability-on-demand
  already keeps Deployer and Playwright off until they are chosen.
- Letterbox 16:9 into 9:16 inside FFmpeg. Rejected. Vertical films are
  composed for the tall frame.
- Fail renders that do not meet the Kinetic Film still-frame and motion
  thresholds. Rejected. Those thresholds describe one demonstration,
  not every brand film.
