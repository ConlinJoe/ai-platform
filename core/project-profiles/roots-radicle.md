# Roots / Radicle / Sage Profile

## Purpose

This profile applies to WordPress projects that use the Roots stack:
Radicle applications and Sage themes (typically with Acorn).

It does **not** apply to:

- Plain WordPress projects that do not use Radicle or Sage
- Laravel web applications (`laravel-webapp`)
- React, Rails, or other non-WordPress stacks

## Technology Stack

Preferred stack (unversioned; subordinate to Current-First Engineering
in `00-platform` — establish installed or current stable versions before
implementation):

- WordPress
- Roots Radicle and/or Sage
- Acorn
- Blade
- Tailwind CSS
- Alpine.js

Greenfield baseline for **new** Roots/Radicle/Sage projects (also
subordinate to Current-First Engineering, Framework-Native First,
compatibility checks, license/credential requirements, and explicit
project ADRs/contracts):

- ACF Pro — structured/editorial field management
- Keen Slider (`keen-slider`) — sliders, carousels, galleries
- WPForms Lite — ordinary/basic forms

Do not force this baseline onto existing projects that already have
intentional alternatives.

## Architecture

- Follow Roots / WordPress / Sage conventions for the installed or
  intentionally selected ecosystem (Current-First Engineering in
  `00-platform`).
- Follow Framework-Native First in `00-platform`.
- WordPress remains the source of truth for content, pages, menus, menu
  locations, menu items, hierarchy, labels, and URLs.
- Navi adapts WordPress navigation into structured data for Sage/Blade.
- Sage/Blade owns presentation. Frontend layout remains code-owned.
- ACF Pro is the preferred structured-content layer. WordPress owns
  native content; ACF owns intentional structured metadata. ACF is not
  a page builder.
- Keen Slider is the preferred slider/carousel/gallery library.
  Integrate it through the project's Sage/Vite frontend architecture.
- WPForms Lite is the default forms layer for ordinary form needs.
  WordPress / WPForms owns form behavior; Sage/Blade/Tailwind owns
  surrounding presentation. Gravity Forms remains a valid
  project-specific choice, not the default.
- A project-native provisioner may establish reproducible
  project-defined WordPress structure. It is not a runtime CMS.
- Acorn provides the Laravel-based application layer inside WordPress.
- Prefer existing patterns over introducing new ones when those patterns
  correctly use the installed stack.

## Navigation

Log1x Navi (`https://github.com/Log1x/navi`) is the preferred navigation
integration for this stack. That preference is subordinate to
Current-First Engineering in `00-platform`.

Before installing or implementing Navi, verify that it is current,
maintained, compatible with the project's installed WordPress / Sage /
Acorn / PHP environment, and still appropriate. Inspect the installed
Navi version (when present) and consult that version's current official
documentation for APIs, generators, and integration patterns. Do not
hard-code historical Navi APIs from model memory.

If the ecosystem changes materially and a better framework-native
approach supersedes Navi, surface that rather than blindly enforcing
this historical preference.

### Ownership

WordPress owns navigation state:

- menus
- menu locations
- menu items
- hierarchy
- labels
- URLs

Navi adapts that state into structured navigation data for the
Sage/Blade layer.

Blade owns markup and presentation.

Do not default to statically coded navigation arrays, duplicated
desktop/mobile navigation sources, custom NavWalker implementations,
custom menu abstractions, or hard-coded URLs for normal WordPress
navigation when WordPress and Navi already provide the capability.

### When Navi is appropriate

1. Use the currently supported Navi API for the installed version.
2. Use registered WordPress menu locations.
3. Build navigation from the WordPress menu/location rather than static
   configuration.
4. Use Navi's native hierarchy and active-state capabilities rather than
   recreating them.
5. Use Navi's supported Sage/Acorn integration and generators where
   appropriate.
6. Drive desktop and mobile navigation from the same WordPress/Navi
   source.
7. Let Blade/Tailwind control markup and presentation.
8. Use Alpine only where interaction genuinely requires it.
9. Do not introduce another navigation package or custom Walker unless
   Navi or native WordPress cannot meet a concrete requirement.

### New projects

If navigation functionality is required and Navi is not installed:

- Verify current Navi compatibility and maintenance.
- Recommend/use Navi as the preferred navigation integration.
- Follow platform Safety rules: do not modify Composer manifests
  without approval. Do not silently install dependencies.

### Existing projects

- Inspect the navigation architecture first.
- If Navi is already installed, use it correctly for the installed
  version.
- Do not replace a working intentional navigation architecture merely
  to standardize unless the task calls for it.
- Do not upgrade Navi automatically.

## Structured content

ACF Pro (`https://www.advancedcustomfields.com/`) is the preferred
structured-content layer for custom Roots/Radicle/Sage sites. That
preference is subordinate to Current-First Engineering and
Framework-Native First in `00-platform`, and to platform Safety rules
for dependencies, licenses, and credentials.

Before installing or implementing ACF Pro, verify that the current
release is compatible with the project's installed WordPress / PHP /
Roots / Sage / Acorn environment, and still appropriate. Inspect the
installed ACF version (when present) and consult that version's current
official documentation. Prefer ACF Composer / existing Roots-native
field architecture when that is already part of the stack. Do not
hard-code historical ACF APIs from model memory.

If ACF Pro later becomes incompatible, abandoned, or a materially better
project-native solution exists, surface that rather than blindly
enforcing this historical preference.

### Ownership

Use ACF Pro for content that benefits from structured editorial
management, such as:

- page-specific structured fields
- options/settings
- product specifications
- galleries
- structured feature content
- repeatable content with a defined schema

WordPress owns native content where appropriate (titles, body, excerpts,
featured images, taxonomies, menus, pages). ACF owns intentional
structured metadata/content. Sage/Blade/Tailwind owns presentation of
those fields.

Do not use ACF to create an unrestricted page builder. Do not default
to giant Flexible Content systems, arbitrary layout builders, "build
anything" repeaters, or duplicating data WordPress already owns
natively.

### Credentials

ACF Pro requires licensing/authentication.

- Never commit license keys, `auth.json` secrets, or credentials.
- Install it automatically only when the project's approved credential
  mechanism makes that possible.
- Otherwise establish/configure the expected field architecture and
  clearly report the credential blocker.
- Do not silently substitute free ACF if the project standard requires
  Pro features.

### New projects

Verify current ACF Pro compatibility and official installation guidance.
Install/activate it when authenticated installation is available. If
credentials block automated installation, report the blocker and
continue the remaining setup. Do not invent a substitute architecture.

### Existing projects

- Inspect the current field architecture first.
- If ACF Pro is already installed, use the current installed
  architecture correctly.
- Preserve an intentional working alternative unless the user requests
  standardization.
- Do not automatically migrate field groups or replace another mature
  structured-content system.
- Do not auto-upgrade solely to satisfy this preference.

## Sliders and galleries

Keen Slider (`https://keen-slider.io/`, npm package `keen-slider`) is
the preferred slider/carousel/gallery library for Roots/Radicle/Sage
frontend work. That preference is subordinate to Current-First
Engineering and Framework-Native First in `00-platform`.

Before installing or implementing Keen, verify that the current
`keen-slider` release is compatible with the project's installed
Node / Sage / Vite environment, and still appropriate. Inspect the
installed version (when present) and consult that version's current
official documentation. Integrate through the existing Sage/Vite
frontend architecture. Do not hard-code historical Keen APIs from
model memory.

If Keen later becomes incompatible, abandoned, or a materially better
project-native solution exists, surface that rather than blindly
enforcing this historical preference.

### When Keen is appropriate

Prefer Keen for:

- product galleries
- image sliders
- carousels
- thumbnail-driven galleries
- touch/drag interactions

Do not automatically add Swiper, Slick, Splide, or another carousel
library when Keen satisfies the requirement. Do not force a slider into
a UI that does not need one. Drive gallery media from WordPress/ACF, not
hard-coded image URLs.

Preferred defaults where applicable:

- no autoplay unless explicitly required
- touch/drag support
- accessible controls
- thumbnails instead of dots when the interface calls for image
  selection
- minimal JS
- no unnecessary wrapper abstraction

### New projects

Install the current compatible `keen-slider` package via the project's
npm workflow even if no slider is designed yet. Do not invent sliders.
Verify Current-First compatibility before install.

### Existing projects

- Inspect the current slider/gallery architecture first.
- If Keen is already installed, use it correctly for the installed
  version.
- Preserve an intentional working alternative (including Swiper) unless
  the user requests migration.
- Do not automatically replace another slider library.
- Do not auto-upgrade solely to satisfy this preference.

## Forms

WPForms Lite (`https://wordpress.org/plugins/wpforms-lite/`) is the
preferred **default** forms plugin for ordinary Roots/Radicle/Sage
projects. That preference is subordinate to Current-First Engineering
and Framework-Native First in `00-platform`.

Use it for normal requirements such as contact forms, lead/inquiry
forms, basic validation, notifications, and simple user submissions.

Before installing or implementing WPForms Lite, verify that the current
release is compatible with the project's installed WordPress / PHP /
Roots / Sage / Acorn environment, and still appropriate. Inspect the
installed version (when present) and consult that version's current
official documentation for APIs, hooks, templates, and theme
integration. Do not hard-code historical WPForms APIs from model
memory.

If WPForms Lite later becomes incompatible, abandoned, or a materially
better project-native default exists, surface that rather than blindly
enforcing this historical preference.

### Decision hierarchy

1. Inspect existing project/form architecture.
2. For greenfield or basic form needs, prefer WPForms Lite.
3. Upgrade WPForms or choose another mature forms system only when
   requirements justify it.
4. Gravity Forms remains a valid project-specific choice, but is **not**
   the default.

Examples that may justify a paid WPForms upgrade or another mature
system: advanced conditional logic, complex integrations, payments,
advanced workflows, sophisticated routing, or requirements Lite does
not support cleanly. Evaluate the actual need. Do not automatically
upgrade.

### Ownership

WordPress / WPForms should own:

- fields
- validation
- submission handling
- notifications
- spam-protection capabilities
- form administration

Sage/Blade/Tailwind should own:

- page composition
- surrounding presentation
- theme integration
- visual treatment

Do not hand-code POST handlers, email delivery, nonce/validation
infrastructure, or custom form storage when WPForms already satisfies
the requirement.

### Theme integration

Do not accept default plugin styling blindly. Integrate WPForms into
the existing Tailwind/design system using supported hooks, classes,
templates, and APIs. Prefer theme-controlled presentation without
forking or editing plugin code. Preserve accessibility, validation
states, error messages, and form behavior. Do not recreate WPForms
functionality merely to gain styling control.

### Provisioning

When a project has known required forms, prefer reproducible setup
where supported. The project contract may define form purpose, fields,
labels, notifications, routing/integrations, and confirmations.

Use supported WPForms APIs, CLI, or import mechanisms if appropriate
and current. Do not write form plugin database tables directly. Do not
overwrite user-edited forms destructively on normal provisioning runs.

### New projects

Verify current WPForms Lite compatibility and official installation
guidance. Once WordPress is available, install and activate WPForms
Lite using the current WordPress/WP-CLI mechanism. Prefer Lite before
purchasing or upgrading. Do not invent an insecure custom fallback.

### Existing projects

- Inspect the current form architecture first.
- Preserve an intentional working solution unless the user requests
  standardization.
- If WPForms is already installed, use it correctly for the installed
  version.
- If Gravity Forms or another mature form system is already installed
  and intentional, keep it. Do not automatically migrate forms.
- Do not auto-upgrade solely to satisfy this preference.

## Greenfield setup

For a **new** Roots/Radicle/Sage project, this baseline is the approved
stack setup. Verify Current-First compatibility before each install.
Other dependency changes still require approval under platform Safety
rules. Never commit license keys or secrets.

Platform `bootstrap-project.sh` installs AI Platform infrastructure. It
does not install npm packages or WordPress plugins. It does guarantee
`resources/images/` on new Roots/Radicle projects. Agents complete the
remaining stack setup as part of the Roots/Radicle project workflow in
`50-workflows`, not because the AI Platform repository itself was
bootstrapped, and not for non-WordPress projects.

1. Ensure `resources/images/` exists (Sage `@images` / theme image
   directory).
2. Install the current compatible `keen-slider` package via the
   project's npm/Vite workflow.
3. Once WordPress is available, install and activate WPForms Lite
   using the current WordPress/WP-CLI mechanism.
4. Install and activate ACF Pro when the project's approved credential
   mechanism makes authenticated installation possible. If credentials
   or license setup prevent it, report the blocker clearly and continue
   the remaining setup. Do not silently substitute free ACF.
5. Do not invent sliders, unrestricted ACF page builders, or custom
   form infrastructure the project does not need.

## Page and menu provisioning

This profile defines **how** project-defined WordPress structure is
established. It does **not** define a universal sitemap.

Individual project contracts own the actual:

- pages
- slugs
- parent/child page relationships
- menu locations
- menu names
- menu items
- menu hierarchy
- navigation labels
- other initial structural content

Do not invent pages, slugs, or menus in this profile or copy one
project's sitemap onto another.

When a project contract defines page/navigation architecture, prefer an
explicit, idempotent, project-native provisioner. Determine the current
framework-native implementation from the installed WordPress / Radicle /
Acorn versions and their official documentation. Do not hard-code a
historical WP-CLI, Acorn, or WordPress command pattern from model
memory.

Prefer a deliberate developer operation (a project-native CLI command or
setup task) so provisioning is explicit and reproducible. Do not turn
the provisioner into a runtime CMS abstraction.

### Responsibilities

Keep these separate:

- WordPress — navigation and content source of truth
- Navi — structured navigation adapter for Sage/Blade
- ACF Pro — intentional structured editorial fields (not a page
  builder, not a substitute for the provisioner)
- Blade — presentation
- Provisioner — reproducible initial / project-defined WordPress
  structure

Do not maintain a duplicate static navigation source in Blade or config
when WordPress is intended to own navigation.

### Required behavior

1. Create only missing pages.
2. Reuse existing pages rather than duplicating them. Match by slug or
   another stable identifier defined by the project contract.
3. Preserve existing IDs.
4. Preserve manually edited page content unless the project contract
   explicitly marks that content as provisioner-owned.
5. Establish intended parent/child relationships.
6. Register menu locations in theme/application code using
   WordPress-native APIs; the provisioner reuses those locations.
7. Create or reuse WordPress menus.
8. Link internal pages with actual WordPress page menu items, not
   hard-coded custom URLs.
9. Establish menu hierarchy and labels defined by the project contract.
10. Assign menus to their intended locations.
11. Be safe to run repeatedly without duplicating pages or menu items.
12. Report conflicts instead of destructively replacing existing
    user-managed structure.

### Must not

- Create pages on normal web requests
- Write directly to the WordPress database
- Depend on manual wp-admin setup as the path to reproducible structure
- Overwrite editorial content casually
- Impose one company's sitemap on another project

### New projects

- Establish this provisioning architecture as part of the stack
  convention.
- Do not invent project pages until a project contract defines them.
- Once page/menu architecture is approved, use the standard provisioner
  rather than creating that structure by hand in wp-admin.
- If the initial contract already defines the sitemap and the
  application environment is operational, the new-project workflow may
  invoke the approved provisioner. Platform `bootstrap-project.sh` does
  not provision WordPress content.

### Existing projects

- Inspect existing page/menu state first.
- Do not automatically re-provision or restructure production content.
- Adopt this provisioning convention only when the user asks to
  standardize or reproducibly manage that structure.

## Development Principles

- Keep solutions simple and maintainable.
- Avoid unnecessary abstractions. Follow Framework-Native First
  before introducing wrappers or extra packages.
- Make focused changes.
- Do not perform unrelated refactoring.

## Documentation

Follow the `10-documentation` project rule.

Use contract-based documentation with `docs/README.md` as the dependency
graph. Maintain `docs/00-project-context.md` for ChatGPT context. Export
project AI context via `scripts/export-chatgpt-context.sh`.

For **new** Roots/Radicle/Sage projects, architecture and project-context
contracts should record, concisely:

- ACF owns structured editorial fields; frontend layout remains
  code-owned; no unrestricted ACF page builder
- Keen is the preferred slider/gallery dependency
- WPForms Lite is the default basic forms layer
- upgrades or alternatives require actual project need
- credentials and secrets are never committed
