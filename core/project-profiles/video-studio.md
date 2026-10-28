# Video studio profile

A video studio is a harness project whose work is films. It does not
require Laravel, WordPress, Roots, or another application framework.

Create one with:

```bash
/path/to/ai-platform/scripts/init-video-studio.sh /path/to/video-studio
```

That command bootstraps the harness, skips Deployer, and installs the
video-production capability in studio mode. It does not render, publish,
or spend generation credits.

## Layout

```text
video/
  studio.json
  campaigns/
    <slug>/
      brief.md
      brand.md
      assets/
      film/
      reviews/
      renders/          gitignored
```

Each campaign owns its brand file and assets. A new campaign is copied
from a brand-free template, not from another campaign.

## Profile detection

Bootstrap reports `video-studio` when `video/studio.json` records studio
mode and the directory is not an application project. Laravel, Roots,
Bedrock, and conventional WordPress stay on their own profiles.
Installing video into those projects uses integrated mode and does not
change how they bootstrap.

## Renderer

The studio uses the same renderer as an integrated project:
`scripts/video-render.sh`. Canonical procedure:
`.agents/skills/video-production/SKILL.md`.
Contract: `docs/contracts/features/video-production.md`.
