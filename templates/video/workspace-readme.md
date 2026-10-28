# Video workspace

This directory is the project's video-production workspace. It is separate
from the application dependency tree.

The harness owns the renderer and the workflow. This project owns the
campaigns under `campaigns/`.

```bash
scripts/video-new-campaign.sh . <slug> ad-15
video/bin/render video/campaigns/<slug>
```

`video/bin/render` is a local render. It does not spend Scenario credits.
It does not publish the file.

Rendered masters, review copies, and the Playwright runtime are gitignored.
Scene source, briefs, and brand files stay in the campaign directory.

One campaign must not reuse another campaign's `brand.md` or `assets/`.
