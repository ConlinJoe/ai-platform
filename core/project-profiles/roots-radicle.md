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

## Architecture

- Follow Roots / WordPress / Sage conventions for the installed or
  intentionally selected ecosystem (Current-First Engineering in
  `00-platform`).
- Follow Framework-Native First in `00-platform`.
- WordPress remains the source of truth for content, pages, menus, menu
  locations, menu items, hierarchy, labels, and URLs.
- Navi adapts WordPress navigation into structured data for Sage/Blade.
- Sage/Blade owns presentation.
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
