#!/usr/bin/env python3
"""Package-scoped stack detection shared by the guardrail scanners.

Template framework checks and Tailwind checks use the nearest relevant
package boundary. A nested npm manifest does not hide an ancestor Composer
framework or an ancestor Tailwind package. A sibling package does not leak
into another package. Uncertain scope is reported and is not treated as a
match for an unrelated rule.
"""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass, field

OTHER_STYLING = {
    "bootstrap",
    "styled-components",
    "@emotion/react",
    "@emotion/styled",
    "@mui/material",
    "bulma",
}
COMPONENT_PACKAGES = {
    "react": "react",
    "react-dom": "react",
    "preact": "preact",
    "vue": "vue",
    "svelte": "svelte",
    "solid-js": "solid",
    "@angular/core": "angular",
}
ROOTS_PACKAGES = {"roots/acorn", "roots/sage", "roots/radicle"}
TAILWIND_ENTRY_RE = re.compile(
    r"""@import\s+["']tailwindcss["']|@tailwind\s+(?:base|components|utilities)\b|@theme\b"""
)


@dataclass
class Pkg:
    rel: str
    tailwind: str | None = None
    bootstrap: str | None = None
    other_styling: list[str] = field(default_factory=list)
    components: dict[str, str] = field(default_factory=dict)
    laravel: str | None = None
    roots: list[str] = field(default_factory=list)
    tailwind_config: bool = False


@dataclass
class Detection:
    packages: list[Pkg] = field(default_factory=list)
    has_blade: bool = False
    unsupported_templates: set[str] = field(default_factory=set)
    has_component_file: bool = False


def load_json(path: str) -> dict | None:
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None
    return data if isinstance(data, dict) else None


def dep_version(deps: dict, name: str) -> str | None:
    value = deps.get(name)
    if value is None:
        return None
    return str(value)


def merged_deps(data: dict) -> dict:
    merged: dict = {}
    for key in ("dependencies", "devDependencies", "peerDependencies"):
        section = data.get(key)
        if isinstance(section, dict):
            merged.update(section)
    return merged


def detect(root: str) -> Detection:
    from check_guardrails import path_is_skipped

    detection = Detection()
    by_rel: dict[str, Pkg] = {}

    def pkg_for(rel_dir: str) -> Pkg:
        rel = "" if rel_dir == "." else rel_dir.replace("\\", "/")
        pkg = by_rel.get(rel)
        if pkg is None:
            pkg = Pkg(rel=rel)
            by_rel[rel] = pkg
        return pkg

    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [name for name in dirnames if name not in {
            ".git",
            ".build",
            ".agents",
            ".cursor",
            ".claude",
            ".grok",
            ".hallmark",
            ".svn",
            "node_modules",
            "vendor",
            "dist",
            "storage",
        }]
        rel_dir = os.path.relpath(dirpath, root)
        if rel_dir != "." and path_is_skipped(rel_dir):
            dirnames[:] = []
            continue
        for filename in filenames:
            rel = os.path.relpath(os.path.join(dirpath, filename), root).replace("\\", "/")
            lower = rel.lower()
            if lower.endswith(".blade.php"):
                detection.has_blade = True
            for suffix in (".twig", ".njk", ".erb", ".cshtml", ".haml", ".slim"):
                if lower.endswith(suffix):
                    detection.unsupported_templates.add(suffix)
            if lower.endswith((".jsx", ".tsx", ".vue", ".svelte")):
                detection.has_component_file = True
            if filename in {
                "tailwind.config.js",
                "tailwind.config.ts",
                "tailwind.config.cjs",
                "tailwind.config.mjs",
            }:
                pkg_for(rel_dir).tailwind_config = True
            if filename == "package.json":
                data = load_json(os.path.join(dirpath, filename))
                if data is None:
                    continue
                pkg = pkg_for(rel_dir)
                deps = merged_deps(data)
                pkg.tailwind = pkg.tailwind or dep_version(deps, "tailwindcss")
                pkg.bootstrap = pkg.bootstrap or dep_version(deps, "bootstrap")
                for name in OTHER_STYLING:
                    if name in deps and name not in pkg.other_styling and name != "bootstrap":
                        pkg.other_styling.append(name)
                for name, label in COMPONENT_PACKAGES.items():
                    version = dep_version(deps, name)
                    if version is not None:
                        pkg.components.setdefault(label, version)
            if filename == "composer.json":
                data = load_json(os.path.join(dirpath, filename))
                if data is None:
                    continue
                pkg = pkg_for(rel_dir)
                require: dict = {}
                for key in ("require", "require-dev"):
                    section = data.get(key)
                    if isinstance(section, dict):
                        require.update(section)
                pkg.laravel = pkg.laravel or dep_version(require, "laravel/framework")
                for name in sorted(ROOTS_PACKAGES):
                    version = dep_version(require, name)
                    if version is not None and name not in pkg.roots:
                        pkg.roots.append(f"{name} {version}")

    detection.packages = [by_rel[key] for key in sorted(by_rel)]
    return detection


def nearest_pkg(detection: Detection, rel_path: str) -> Pkg | None:
    best: Pkg | None = None
    for pkg in detection.packages:
        root = pkg.rel
        if root == "" or rel_path == root or rel_path.startswith(root + "/"):
            if best is None or len(root) > len(best.rel):
                best = pkg
    return best


def styling_label(pkg: Pkg) -> str:
    parts: list[str] = []
    if pkg.tailwind or pkg.tailwind_config:
        declared = pkg.tailwind or "config"
        parts.append(f"tailwindcss {declared}")
    if pkg.bootstrap:
        parts.append(f"bootstrap {pkg.bootstrap}")
    parts.extend(pkg.other_styling)
    return ", ".join(parts) if parts else "no styling package"


def package_uses_tailwind(pkg: Pkg) -> bool:
    return bool(pkg.tailwind or pkg.tailwind_config)


def package_other_styling(pkg: Pkg) -> bool:
    return bool(pkg.bootstrap or pkg.other_styling)


def composer_mode(pkg: Pkg) -> str | None:
    if pkg.laravel and pkg.roots:
        return "laravel+roots"
    if pkg.roots:
        return "roots"
    if pkg.laravel:
        return "laravel"
    return None


def repo_has_tailwind(detection: Detection) -> bool:
    return any(package_uses_tailwind(pkg) for pkg in detection.packages)


def _package_at(detection: Detection, rel_dir: str) -> Pkg | None:
    key = "" if rel_dir in ("", ".") else rel_dir
    for pkg in detection.packages:
        if pkg.rel == key:
            return pkg
    return None


def tailwind_scope(detection: Detection, rel_path: str, text: str | None) -> tuple[str, str]:
    """Return applicable, not-applicable, or uncertain, plus the reason.

    Applicable means Tailwind-specific checks run. Uncertain means Tailwind
    exists somewhere else and this file is outside that package boundary, so
    the Tailwind checks do not run. Not-applicable means this file's own
    styling system is something else, or the repository has no Tailwind evidence.
    """
    rel_path = rel_path.replace("\\", "/")
    if rel_path.endswith(".module.css") or rel_path.endswith(".module.scss"):
        return "not-applicable", "CSS Modules file; Tailwind checks not applied"
    pkg = nearest_pkg(detection, rel_path)
    if pkg is not None and package_uses_tailwind(pkg):
        where = pkg.rel or "."
        return "applicable", f"package {where} ({styling_label(pkg)})"
    if pkg is not None and package_other_styling(pkg) and not package_uses_tailwind(pkg):
        where = pkg.rel or "."
        return "not-applicable", f"package {where} uses {styling_label(pkg)} without Tailwind"

    rel_dir = os.path.dirname(rel_path)
    while True:
        key = "" if rel_dir in ("", ".") else rel_dir
        ancestor = _package_at(detection, key)
        if ancestor is not None and (pkg is None or ancestor.rel != pkg.rel):
            if package_uses_tailwind(ancestor) and not (
                pkg is not None and package_other_styling(pkg)
            ):
                where = ancestor.rel or "."
                return "applicable", f"ancestor package {where} ({styling_label(ancestor)})"
            if package_other_styling(ancestor) and not package_uses_tailwind(ancestor):
                where = ancestor.rel or "."
                return (
                    "not-applicable",
                    f"ancestor package {where} uses {styling_label(ancestor)} without Tailwind",
                )
        if key == "":
            break
        parent = os.path.dirname(key)
        if parent == rel_dir:
            break
        rel_dir = parent

    if text is not None and TAILWIND_ENTRY_RE.search(text):
        return "applicable", "this file is a Tailwind entry or theme file"
    if repo_has_tailwind(detection):
        return (
            "uncertain",
            "Tailwind is declared in another package; this file is outside that scope, "
            "so Tailwind rules were not applied",
        )
    return "not-applicable", "no Tailwind package, config, or entry file covers this file"
