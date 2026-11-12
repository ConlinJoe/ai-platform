# Video workspace

This directory is the project's video-production workspace. It is separate
from the application dependency tree.

The harness owns the renderer and the workflow. This project owns the
campaigns under `campaigns/`.

```bash
scripts/video-new-campaign.sh . <slug> ad-15
video/bin/preview video/campaigns/<slug>
video/bin/render video/campaigns/<slug>
```

`video/bin/preview` binds to 127.0.0.1 and serves that campaign only.
`video/bin/render` is a local render. It does not spend Scenario credits.
It does not publish the file.

Raw photos, video binaries, drafts, renders, and temporary output under
this workspace are gitignored. Scene source, specs, scripts, briefs, and
brand notes stay in Git.

One campaign must not reuse another campaign's `brand.md` or `assets/`.
