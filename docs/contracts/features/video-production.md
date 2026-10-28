---
status: active
last_reviewed: 2026-10-28
source_of_truth_for:
  - Optional video-production capability, both project modes, and the local renderer
  - Separation of local rendering from paid generation and from publication
  - Decision not to redistribute the Scenario Kinetic Film package
depends_on:
  - ../adrs/0010-optional-video-production.md
  - browser-qa.md
referenced_by:
  - ../adrs/0010-optional-video-production.md
type: feature
---

# Video production

Video production is an optional harness capability. It is off until a
developer installs it. Installing it does not render a film, publish a
file, upload media, or spend generation credits.

The procedure for agents is `.agents/skills/video-production/SKILL.md`.
This contract is the behavior. The decision is ADR 0010.

## Two modes, one renderer

| Mode | When | Command |
| --- | --- | --- |
| A. Integrated | An existing application project | `scripts/install-video-production.sh <project>` |
| B. Studio | A new video-only directory | `scripts/init-video-studio.sh <directory>` |

Studio initialization bootstraps the harness with `--without-deployer`,
then installs studio mode. It does not create Laravel, WordPress, or
Node application dependencies. Re-running bootstrap on that directory
reports `Detected profile: video-studio`.

An application project that also has a video workspace stays on its
application profile. Video is reported as installed, not as a
replacement profile.

Ordinary bootstrap does not install video and does not prompt. Pass
`--with-video` to install integrated mode during bootstrap. There is
no interactive video prompt.

Both modes create:

```text
video/studio.json
video/campaigns/<slug>/
video/bin/render
.agents/skills/video-production
```

The skill and render command are symlinks into the harness clone.
Campaign source stays in the project. Customer photography, logos, and
finished masters do not belong in the harness repository.

`video/.runtime/` and `video/campaigns/*/renders/` are gitignored.
The installer does not delete an existing `video/` directory that
lacks the harness marker.

## Campaigns

```bash
scripts/video-new-campaign.sh <project> <slug> <template> [--format ...]
```

Templates shipped with the harness:

| Template | Stage | Duration |
| --- | --- | --- |
| `ad-15` | 1920x1080 | 15 s |
| `ad-15-vertical` | 1080x1920 | 15 s |
| `hero` | 1920x1080 | 8 s |
| `announcement` | 1920x1080 | 12 s |
| `identity` | 1920x1080 | 8 s |
| `smoke` | 640x360 | 0.5 s, synthetic |

`--format` may retarget a template:

| Format | Pixels | Notes |
| --- | --- | --- |
| `landscape` | 1920x1080 | Default production frame |
| `vertical` | 1080x1920 | Native tall composition |
| `square` | 1080x1080 | Supported stage size |
| `social` | 1080x1350 | 4:5 stage size |

The stage element is that size. A vertical campaign is not a landscape
film padded with bars.

A new campaign copies the named template and a blank brand file. It
does not copy another campaign. Placeholder words say "Brand" until
the project replaces them with approved copy.

## Local renderer

`scripts/video-render.sh <campaign>`:

1. Checks that FFmpeg, ffprobe, Node, and Python 3 exist.
2. Installs Playwright 1.64.1 into `video/.runtime` with npm scripts
   ignored, so Chromium is not downloaded.
3. Launches the system Google Chrome, one worker, against the local
   film page only.
4. Seeks `window.__videoSeek(time)` and writes PNG frames to FFmpeg.
5. Writes an H.264 High master (yuv420p, BT.709, TV range, `+faststart`),
   a smaller review file, stills, and a contact sheet.
6. Runs `scripts/video/validate.py`.

Default master quality is CRF 16 and preset `medium`. Override with
`VIDEO_X264_CRF` and `VIDEO_X264_PRESET` when a campaign needs a
different master. Default rate is the campaign `fps` (30 for the
production templates).

`--resolution 4k` renders at device scale 2. It is refused when the
machine reports under 12 GB of memory. 4K is not required.

The worker count is calculated from memory and CPU and then capped at
1. One Chrome process keeps a long render from competing with the rest
of the machine. The command does not quit other applications or change
system settings.

An existing master is kept unless `--replace` is passed. A failed
encode removes its partial file and leaves any previous master.

Audio is off unless `spec.js` sets `audio` to a file inside the
campaign. The mux keeps the video duration. Silence is a finished
delivery.

This path does not call Scenario. The shell exits 2 if it is given a
paid-generation flag.

Set `VIDEO_ALLOW_PLAYWRIGHT_BROWSER=1` only when the developer has
agreed to a Playwright Chromium download. The default is the installed
Google Chrome.

## Validation

Technical checks fail the command: file present, dimensions, H.264,
yuv420p, frame rate, frame count, duration, BT.709 tags, audio present
only when requested, a clean FFmpeg decode, and a film that is not
entirely black.

Creative notes do not fail the file: black frames that are not the
whole film, possible white flashes, holds, cropdetect borders, type
readability, logo ratio, source-image ratio, and whether the motion
fits the brand. The agent inspects the review MP4 and the stills.
A successful encode is not design approval.

The Kinetic Film demonstration's minimum motion and maximum hold rules
are not global gates.

## Paid generation and publication

Local rendering does not spend Scenario credits. Say that when a render
starts. Do not describe it as free of all cost: the machine and the
agent model still have a cost.

Before a provider generates an image, a video, or audio:

1. Name the provider and the model.
2. Verify the price with a dry run.
3. Describe the intended file.
4. Get explicit authorization.
5. Stay inside the budget.
6. Do not spend credits again on an automatic retry.

Do not upload confidential or unapproved media. Do not treat a local
render as permission to publish or deploy.

## Browser authorization

Capturing frames of the local film page is allowed for this capability
only. It is not Mode A, not Mode B, and not permission to drive the
application. Application browser QA does not by itself permit a video
render. See `browser-qa.md` and `60-browser-qa`.

## Licensing

Do not add the Scenario Kinetic Film engine, its examples, or its
fonts to this repository. The fonts in that package are SIL OFL. The
engine code had no stated license in the package that was tested.
`scenario-labs/skills` is MIT and does not contain this engine. Its
kinetic music-video skill is a different product.

The stage, scripts, and skill in this repository are harness-original
and covered by the repository MIT license. Attribution of the method
(code-timed frames, headless capture, FFmpeg, a technical check) is
recorded in ADR 0010. That attribution is not a redistribution of the
upstream package.

## What stays unchanged

Impeccable and Hallmark routing, the website comp gate, Deployer,
ordinary bootstrap of application projects, and `skills-lock.json`
(still `hallmark` and `impeccable` only). The video skill is
harness-owned. It is not an upstream pin. If a skill sync removes the
project symlink, run the installer again.
