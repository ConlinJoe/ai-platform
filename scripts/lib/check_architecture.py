#!/usr/bin/env python3
"""Stack-native architecture checks for template views and Tailwind CSS.

High-confidence findings fail the command. Review items and coverage notes
do not. A clean result does not prove the architecture is correct.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass, field

from check_guardrails import iter_all_files, path_is_in_scope, path_is_skipped, read_text

BASELINE_REL = "docs/architecture-baseline.txt"
KINDS = {
    "template-query",
    "template-persistence",
    "template-preparation",
    "template-orchestration",
    "tailwind-apply",
    "tailwind-utility-css",
}
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
SKIP_AT_BLOCKS = {
    "theme",
    "font-face",
    "keyframes",
    "utility",
    "custom-variant",
    "config",
    "page",
    "counter-style",
    "font-feature-values",
    "color-profile",
}
DIRECTIVES = (
    "elseif",
    "foreach",
    "forelse",
    "empty",
    "isset",
    "unless",
    "while",
    "switch",
    "class",
    "style",
    "checked",
    "selected",
    "disabled",
    "readonly",
    "required",
    "aware",
    "props",
    "case",
    "for",
    "if",
)
UNSUPPORTED_TEMPLATE_SUFFIXES = (
    ".twig",
    ".njk",
    ".erb",
    ".cshtml",
    ".haml",
    ".slim",
)
COMPONENT_SUFFIXES = (".jsx", ".tsx", ".vue", ".svelte")
WEAK_REASONS = {
    "ok",
    "okay",
    "exception",
    "allow",
    "allowed",
    "false positive",
    "legacy",
    "todo",
    "fixme",
    "pass",
    "ignore",
    "skip",
    "temp",
    "temporary",
    "hack",
    "workaround",
    "needed",
    "necessary",
    "because",
    "yes",
    "fine",
    "wip",
    "not applicable",
}
ELOQUENT_RE = re.compile(
    r"\bDB::"
    r"|::query\s*\("
    r"|::where(?:In|Has|DoesntHave|NotIn|Null|NotNull|Between|Date|Column|Exists)?\s*\("
    r"|::find(?:OrFail|OrNew)?\s*\("
    r"|::firstWhere\s*\("
    r"|::firstOrFail\s*\("
    r"|::firstOrCreate\s*\("
    r"|::paginate\s*\("
    r"|::simplePaginate\s*\("
    r"|::cursorPaginate\s*\("
    r"|::withCount\s*\("
    r"|::updateOrCreate\s*\("
    r"|::with\s*\("
)
WP_RE = re.compile(
    r"\bnew\s+WP_Query\b"
    r"|\bWP_Query\b"
    r"|\bget_posts\s*\("
    r"|\bget_post\s*\("
    r"|\bwp_remote_(?:get|post|request)\s*\("
)
ROOTS_FIELD_RE = re.compile(r"\bget_fields?\s*\(|\bthe_field\s*\(")
PERSIST_RE = re.compile(
    r"->save\s*\("
    r"|->delete\s*\("
    r"|->forceDelete\s*\("
    r"|::create\s*\("
    r"|::insert\s*\("
    r"|::destroy\s*\("
    r"|\bMail::"
    r"|\bHttp::"
    r"|\bStorage::(?:put|delete|write|move|copy)\s*\("
    r"|\bCache::(?:put|forever|forget|flush)\s*\("
)
ORCH_RE = re.compile(r"\bapp\s*\(|\bresolve\s*\(")
PREP_RE = re.compile(
    r"\bcollect\s*\("
    r"|->(?:map|filter|reduce|flatMap|mapWithKeys|groupBy|pluck|sortBy|sortByDesc|unique)\s*\("
    r"|\barray_(?:map|filter|reduce)\s*\("
    r"|\bjson_decode\s*\("
    r"|\bpreg_(?:match|match_all|replace|replace_callback|split)\s*\("
    r"|\bstrip_tags\s*\("
    r"|\bfile_get_contents\s*\("
    r"|\bsimplexml_load_\w+"
    r"|\bDOMDocument\b"
    r"|\bfunction\s*\("
)
LOOP_RE = re.compile(r"\b(?:foreach|for|while)\b")
APPEND_RE = re.compile(r"\$\w+\s*\[\s*\]\s*=|\barray_push\s*\(")
ALLOW_RE = re.compile(r"guardrail-allow-architecture\s*:\s*(.*)$", re.IGNORECASE)
FILE_ALLOW_RE = re.compile(r"guardrail-allow-file:\s*([^\n]+)", re.IGNORECASE)
TAILWIND_ENTRY_RE = re.compile(
    r"""@import\s+["']tailwindcss["']|@tailwind\s+(?:base|components|utilities)\b|@theme\b"""
)
SINGLE_CLASS_RE = re.compile(r"\.[_A-Za-z][\w-]*")
SPACING_STEPS = {
    0,
    0.5,
    1,
    1.5,
    2,
    2.5,
    3,
    3.5,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    14,
    16,
    20,
    24,
    28,
    32,
    36,
    40,
    44,
    48,
    52,
    56,
    60,
    64,
    72,
    80,
    96,
}
FONT_SIZES = {
    0.75: "text-xs",
    0.875: "text-sm",
    1.0: "text-base",
    1.125: "text-lg",
    1.25: "text-xl",
    1.5: "text-2xl",
    1.875: "text-3xl",
    2.25: "text-4xl",
    3.0: "text-5xl",
    3.75: "text-6xl",
    4.5: "text-7xl",
    6.0: "text-8xl",
    8.0: "text-9xl",
}
RADIUS = {
    0.0: "rounded-none",
    0.125: "rounded-sm",
    0.25: "rounded",
    0.375: "rounded-md",
    0.5: "rounded-lg",
    0.75: "rounded-xl",
    1.0: "rounded-2xl",
    1.5: "rounded-3xl",
}
MAX_FILE_CHARS = 1_000_000


@dataclass
class Finding:
    path: str
    line: int
    kind: str
    detail: str
    severity: str = "fail"


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


def normalize_snippet(line: str) -> str:
    collapsed = re.sub(r"\s+", " ", line.replace("\t", " ")).strip()
    return collapsed[:160]


def reason_is_valid(raw: str) -> bool:
    cleaned = raw.strip()
    cleaned = re.sub(r"\s*(?:\*/|--\}\}|-->)\s*$", "", cleaned).strip(" \"'")
    if len(cleaned) < 20:
        return False
    normalized = re.sub(r"[^a-z0-9 ]+", "", cleaned.lower())
    normalized = re.sub(r"\s+", " ", normalized).strip()
    return normalized not in WEAK_REASONS


def line_allowance(lines: list[str], index: int) -> str:
    """Return allow, reject, or none for a finding on this line."""
    current = lines[index] if 0 <= index < len(lines) else ""
    previous = lines[index - 1] if index > 0 else ""
    saw_invalid = False
    for candidate in (current, previous):
        match = ALLOW_RE.search(candidate)
        if match is None:
            continue
        if reason_is_valid(match.group(1)):
            return "allow"
        saw_invalid = True
    return "reject" if saw_invalid else "none"


def file_allow_architecture(lines: list[str]) -> int | None:
    for index, line in enumerate(lines[:30]):
        match = FILE_ALLOW_RE.search(line)
        if match is None:
            continue
        payload = match.group(1).lower()
        if re.search(r"\barchitecture\b", payload):
            return index + 1
    return None


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
            for suffix in UNSUPPORTED_TEMPLATE_SUFFIXES:
                if lower.endswith(suffix):
                    detection.unsupported_templates.add(suffix)
            if lower.endswith(COMPONENT_SUFFIXES):
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


def template_mode(detection: Detection) -> str:
    laravel = any(pkg.laravel for pkg in detection.packages)
    roots = any(pkg.roots for pkg in detection.packages)
    if laravel and roots:
        return "laravel+roots"
    if roots:
        return "roots"
    if laravel:
        return "laravel"
    if detection.has_blade:
        return "uncertain"
    return "none"


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


def tailwind_scope(detection: Detection, rel_path: str, text: str | None) -> tuple[bool, str]:
    if rel_path.endswith(".module.css") or rel_path.endswith(".module.scss"):
        return False, "CSS Modules file; Tailwind custom-CSS check not applied"
    pkg = nearest_pkg(detection, rel_path)
    if pkg is not None and package_uses_tailwind(pkg):
        where = pkg.rel or "."
        return True, f"package {where} ({styling_label(pkg)})"
    if pkg is not None and package_other_styling(pkg) and not package_uses_tailwind(pkg):
        where = pkg.rel or "."
        return False, f"package {where} uses {styling_label(pkg)} without Tailwind"
    # Inherit an ancestor Tailwind package when no nearer package picks another system.
    rel_dir = os.path.dirname(rel_path)
    while True:
        ancestor = nearest_pkg(detection, rel_dir if rel_dir not in ("", ".") else ".")
        if ancestor is not None and ancestor.rel != (pkg.rel if pkg else None):
            if package_uses_tailwind(ancestor) and not (
                pkg is not None and package_other_styling(pkg)
            ):
                where = ancestor.rel or "."
                return True, f"ancestor package {where} ({styling_label(ancestor)})"
            if package_other_styling(ancestor) and not package_uses_tailwind(ancestor):
                break
        if rel_dir in ("", "."):
            break
        parent = os.path.dirname(rel_dir)
        if parent == rel_dir:
            break
        rel_dir = parent
    if text is not None and TAILWIND_ENTRY_RE.search(text):
        return True, "this file is a Tailwind entry or theme file"
    return False, "no Tailwind package, config, or entry file covers this CSS"


def is_template(rel_path: str) -> bool:
    lower = rel_path.replace("\\", "/").lower()
    if "/view/composers/" in lower or "/view/components/" in f"/{lower}":
        if not lower.endswith(".blade.php"):
            return False
    if lower.endswith(".blade.php"):
        return True
    if lower.endswith(".php") and (
        lower.startswith("resources/views/") or "/resources/views/" in lower
    ):
        return False if "/view/composers/" in lower else True
    return False


def is_component_file(rel_path: str) -> bool:
    lower = rel_path.lower()
    return lower.endswith(COMPONENT_SUFFIXES)


def blank_span(chars: list[str], start: int, end: int) -> None:
    for index in range(start, min(end, len(chars))):
        if chars[index] != "\n":
            chars[index] = " "


def skip_string(text: str, index: int) -> int:
    quote = text[index]
    index += 1
    while index < len(text):
        if text[index] == "\\":
            index += 2
            continue
        if text[index] == quote:
            return index + 1
        index += 1
    return index


def mask_php(code: str) -> str:
    chars = list(code)
    index = 0
    length = len(code)
    while index < length:
        if code.startswith("<<<", index):
            match = re.match(r"<<<['\"]?([A-Za-z_]\w*)['\"]?", code[index:])
            if match is not None:
                ident = match.group(1)
                end = re.search(rf"\n{re.escape(ident)};?", code[index + match.end() :])
                stop = length if end is None else index + match.end() + end.end()
                blank_span(chars, index, stop)
                index = stop
                continue
        char = code[index]
        if char in ("'", '"'):
            stop = skip_string(code, index)
            blank_span(chars, index, stop)
            index = stop
            continue
        if code.startswith("//", index) or char == "#":
            stop = code.find("\n", index)
            stop = length if stop < 0 else stop
            blank_span(chars, index, stop)
            index = stop
            continue
        if code.startswith("/*", index):
            stop = code.find("*/", index + 2)
            stop = length if stop < 0 else stop + 2
            blank_span(chars, index, stop)
            index = stop
            continue
        index += 1
    return "".join(chars)


def line_at(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def balanced_end(text: str, start: int, open_char: str, close_char: str) -> int:
    depth = 0
    index = start
    while index < len(text):
        if text.startswith("/*", index):
            stop = text.find("*/", index + 2)
            index = len(text) if stop < 0 else stop + 2
            continue
        if text[index] in ("'", '"'):
            index = skip_string(text, index)
            continue
        if text[index] == open_char:
            depth += 1
        elif text[index] == close_char:
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    return len(text)


@dataclass
class Region:
    kind: str
    start: int
    code: str


def extract_regions(text: str) -> list[Region]:
    chars = list(text)
    # Blade comments are not PHP, even when they mention a query.
    index = 0
    while True:
        start = text.find("{{--", index)
        if start < 0:
            break
        stop = text.find("--}}", start + 4)
        stop = len(text) if stop < 0 else stop + 4
        blank_span(chars, start, stop)
        index = stop
    working = "".join(chars)
    regions: list[Region] = []

    def consume(pattern: str, kind: str, end_token: str) -> None:
        nonlocal working
        chars_now = list(working)
        cursor = 0
        while True:
            start = working.find(pattern, cursor)
            if start < 0:
                return
            if pattern == "@php" and (
                (start >= 3 and working[start - 3 : start] == "end")
                or (start + 4 < len(working) and working[start + 4].isalnum())
            ):
                cursor = start + 4
                continue
            content_start = start + len(pattern)
            end = working.find(end_token, content_start)
            if end < 0:
                end = len(working)
                content_end = end
                consumed = end
            else:
                content_end = end
                consumed = end + len(end_token)
            regions.append(Region(kind, content_start, working[content_start:content_end]))
            blank_span(chars_now, start, consumed)
            working = "".join(chars_now)
            cursor = consumed

    consume("@php", "block", "@endphp")
    consume("<?=", "echo", "?>")
    consume("<?php", "block", "?>")

    chars_now = list(working)
    cursor = 0
    while cursor < len(working):
        if working.startswith("{{", cursor) or working.startswith("{!!", cursor):
            marker = "{{" if working.startswith("{{", cursor) else "{!!"
            closer = "}}" if marker == "{{" else "!!}"
            content_start = cursor + len(marker)
            end = working.find(closer, content_start)
            if end < 0:
                break
            regions.append(Region("echo", content_start, working[content_start:end]))
            blank_span(chars_now, cursor, end + len(closer))
            working = "".join(chars_now)
            cursor = end + len(closer)
            continue
        if working.startswith("@", cursor):
            name = None
            name_end = cursor + 1
            for candidate in DIRECTIVES:
                end = cursor + 1 + len(candidate)
                if working.startswith(candidate, cursor + 1) and (
                    end >= len(working) or not (working[end].isalnum() or working[end] == "_")
                ):
                    name = candidate
                    name_end = end
                    break
            if name is not None:
                look = name_end
                while look < len(working) and working[look].isspace():
                    look += 1
                if look < len(working) and working[look] == "(":
                    stop = balanced_end(working, look, "(", ")")
                    regions.append(Region("echo", look + 1, working[look + 1 : stop - 1]))
                    blank_span(chars_now, cursor, stop)
                    working = "".join(chars_now)
                    cursor = stop
                    continue
        cursor += 1
    return regions


def add_matches(
    findings: list[Finding],
    rel_path: str,
    text: str,
    region: Region,
    masked: str,
    pattern: re.Pattern[str],
    kind: str,
    detail: str,
) -> None:
    for match in pattern.finditer(masked):
        findings.append(
            Finding(
                path=rel_path,
                line=line_at(text, region.start + match.start()),
                kind=kind,
                detail=detail,
            )
        )


def scan_template(rel_path: str, text: str, mode: str) -> list[Finding]:
    findings: list[Finding] = []
    if mode == "none":
        return findings
    for region in extract_regions(text):
        masked = mask_php(region.code)
        add_matches(
            findings,
            rel_path,
            text,
            region,
            masked,
            ELOQUENT_RE,
            "template-query",
            "query or data-access call in a template",
        )
        if mode in {"laravel", "laravel+roots", "roots"}:
            add_matches(
                findings,
                rel_path,
                text,
                region,
                masked,
                WP_RE,
                "template-query",
                "WordPress query in a template",
            )
        if mode in {"roots", "laravel+roots"}:
            add_matches(
                findings,
                rel_path,
                text,
                region,
                masked,
                ROOTS_FIELD_RE,
                "template-query",
                "field read in a Roots/Sage template; prepare it in a composer or equivalent",
            )
        add_matches(
            findings,
            rel_path,
            text,
            region,
            masked,
            PERSIST_RE,
            "template-persistence",
            "persistence or outbound side effect in a template",
        )
        add_matches(
            findings,
            rel_path,
            text,
            region,
            masked,
            ORCH_RE,
            "template-orchestration",
            "service location in a template",
        )
        if region.kind != "block":
            continue
        add_matches(
            findings,
            rel_path,
            text,
            region,
            masked,
            PREP_RE,
            "template-preparation",
            "data preparation in a template PHP block",
        )
        if LOOP_RE.search(masked) and APPEND_RE.search(masked):
            findings.append(
                Finding(
                    path=rel_path,
                    line=line_at(text, region.start),
                    kind="template-preparation",
                    detail="loop accumulates a new data structure in a template PHP block",
                )
            )
        if masked.count(";") >= 15:
            findings.append(
                Finding(
                    path=rel_path,
                    line=line_at(text, region.start),
                    kind="template-preparation",
                    detail="template PHP block contains 15 or more statements",
                )
            )
    return dedupe(findings)


def format_step(value: float) -> str:
    if abs(value - round(value)) < 0.001:
        return str(int(round(value)))
    return f"{value:.1f}".rstrip("0").rstrip(".")


def spacing_token(value: str) -> str | None:
    raw = value.strip().lower()
    if raw in {"0", "0px", "0rem"}:
        return "0"
    if raw == "1px":
        return "px"
    match = re.fullmatch(r"(-?\d+(?:\.\d+)?)(rem|px)", raw)
    if match is None:
        return None
    amount = float(match.group(1))
    unit = match.group(2)
    if amount < 0:
        return None
    steps = amount / 0.25 if unit == "rem" else amount / 4
    for known in SPACING_STEPS:
        if abs(steps - known) < 0.001:
            return "px" if known == 0 and unit == "px" and amount == 1 else format_step(known)
    return None


def nearest_font_size(value: str) -> str | None:
    match = re.fullmatch(r"(\d+(?:\.\d+)?)rem", value.strip().lower())
    if match is None:
        return None
    amount = float(match.group(1))
    for size, utility in FONT_SIZES.items():
        if abs(amount - size) < 0.001:
            return utility
    return None


def nearest_radius(value: str) -> str | None:
    raw = value.strip().lower()
    if raw in {"9999px", "999px"}:
        return "rounded-full"
    match = re.fullmatch(r"(\d+(?:\.\d+)?)rem", raw)
    if match is None:
        return None
    amount = float(match.group(1))
    for size, utility in RADIUS.items():
        if abs(amount - size) < 0.001:
            return utility
    return None


def box_utility(prefix: str, value: str) -> str | None:
    parts = value.split()
    if len(parts) == 1:
        if prefix == "m" and parts[0].lower() == "auto":
            return "m-auto"
        token = spacing_token(parts[0])
        return None if token is None else f"{prefix}-{token}"
    if len(parts) == 2 and prefix == "m" and parts[0] in {"0", "0px"} and parts[1].lower() == "auto":
        return "mx-auto my-0"
    tokens = [spacing_token(part) for part in parts]
    if any(token is None for token in tokens):
        return None
    assert all(token is not None for token in tokens)
    if len(tokens) == 2:
        return f"{prefix}y-{tokens[0]} {prefix}x-{tokens[1]}"
    if len(tokens) == 4:
        edges = ("t", "r", "b", "l")
        return " ".join(f"{prefix}{edge}-{token}" for edge, token in zip(edges, tokens))
    return None


def utility_for(prop: str, value: str) -> str | None:
    prop = prop.strip().lower()
    raw = re.sub(r"\s*!important\s*$", "", value.strip(), flags=re.IGNORECASE).strip().lower()
    raw = re.sub(r"\s+", " ", raw)
    display = {
        "flex": "flex",
        "inline-flex": "inline-flex",
        "grid": "grid",
        "inline-grid": "inline-grid",
        "block": "block",
        "inline-block": "inline-block",
        "inline": "inline",
        "none": "hidden",
        "contents": "contents",
        "flow-root": "flow-root",
    }
    if prop == "display" and raw in display:
        return display[raw]
    if prop in {"gap", "row-gap", "column-gap"}:
        token = spacing_token(raw)
        if token is None:
            return None
        name = {"gap": "gap", "row-gap": "gap-y", "column-gap": "gap-x"}[prop]
        return f"{name}-{token}"
    if prop in {"margin", "padding"}:
        return box_utility("m" if prop == "margin" else "p", raw)
    longhand = {
        "margin-top": "mt",
        "margin-right": "mr",
        "margin-bottom": "mb",
        "margin-left": "ml",
        "margin-inline-start": "ms",
        "margin-inline-end": "me",
        "padding-top": "pt",
        "padding-right": "pr",
        "padding-bottom": "pb",
        "padding-left": "pl",
        "padding-inline-start": "ps",
        "padding-inline-end": "pe",
    }
    if prop in longhand:
        token = spacing_token(raw)
        return None if token is None else f"{longhand[prop]}-{token}"
    if prop == "font-size":
        return nearest_font_size(raw)
    if prop == "font-weight":
        weights = {
            "100": "font-thin",
            "200": "font-extralight",
            "300": "font-light",
            "400": "font-normal",
            "500": "font-medium",
            "600": "font-semibold",
            "700": "font-bold",
            "800": "font-extrabold",
            "900": "font-black",
            "normal": "font-normal",
            "bold": "font-bold",
        }
        return weights.get(raw)
    if prop == "text-align":
        aligns = {
            "left": "text-left",
            "center": "text-center",
            "right": "text-right",
            "justify": "text-justify",
            "start": "text-start",
            "end": "text-end",
        }
        return aligns.get(raw)
    if prop == "flex-direction":
        directions = {
            "row": "flex-row",
            "column": "flex-col",
            "row-reverse": "flex-row-reverse",
            "column-reverse": "flex-col-reverse",
        }
        return directions.get(raw)
    if prop == "flex-wrap":
        wraps = {"wrap": "flex-wrap", "nowrap": "flex-nowrap", "wrap-reverse": "flex-wrap-reverse"}
        return wraps.get(raw)
    if prop == "align-items":
        items = {
            "center": "items-center",
            "flex-start": "items-start",
            "start": "items-start",
            "flex-end": "items-end",
            "end": "items-end",
            "stretch": "items-stretch",
            "baseline": "items-baseline",
        }
        return items.get(raw)
    if prop == "justify-content":
        justify = {
            "center": "justify-center",
            "flex-start": "justify-start",
            "start": "justify-start",
            "flex-end": "justify-end",
            "end": "justify-end",
            "space-between": "justify-between",
            "space-around": "justify-around",
            "space-evenly": "justify-evenly",
        }
        return justify.get(raw)
    if prop == "position":
        positions = {
            "static": "static",
            "relative": "relative",
            "absolute": "absolute",
            "fixed": "fixed",
            "sticky": "sticky",
        }
        return positions.get(raw)
    if prop == "border-radius":
        return nearest_radius(raw)
    if prop in {"width", "height"}:
        prefix = "w" if prop == "width" else "h"
        if raw == "100%":
            return f"{prefix}-full"
        if raw == "auto":
            return f"{prefix}-auto"
        if raw == "100vw" and prop == "width":
            return "w-screen"
        if raw == "100vh" and prop == "height":
            return "h-screen"
        token = spacing_token(raw)
        return None if token is None else f"{prefix}-{token}"
    if prop == "overflow":
        overflows = {
            "hidden": "overflow-hidden",
            "auto": "overflow-auto",
            "scroll": "overflow-scroll",
            "visible": "overflow-visible",
        }
        return overflows.get(raw)
    if prop == "white-space" and raw == "nowrap":
        return "whitespace-nowrap"
    return None


def strip_css_comments(text: str) -> str:
    chars = list(text)
    index = 0
    while True:
        start = text.find("/*", index)
        if start < 0:
            break
        stop = text.find("*/", start + 2)
        stop = len(text) if stop < 0 else stop + 2
        blank_span(chars, start, stop)
        index = stop
    return "".join(chars)


def split_declarations(body: str) -> list[tuple[str, str]]:
    stripped = strip_css_comments(body)
    parts: list[str] = []
    current: list[str] = []
    index = 0
    while index < len(stripped):
        char = stripped[index]
        if char in ("'", '"'):
            stop = skip_string(stripped, index)
            current.append(stripped[index:stop])
            index = stop
            continue
        if char == ";":
            parts.append("".join(current).strip())
            current = []
            index += 1
            continue
        if char == "{":
            return []
        current.append(char)
        index += 1
    tail = "".join(current).strip()
    if tail:
        parts.append(tail)
    declarations: list[tuple[str, str]] = []
    for part in parts:
        if not part or part.startswith("@") or ":" not in part:
            continue
        prop, _, value = part.partition(":")
        declarations.append((prop.strip(), value.strip()))
    return declarations


def single_class_selectors(selector: str) -> bool:
    parts = [part.strip() for part in selector.split(",")]
    if not parts or any(part == "" for part in parts):
        return False
    return all(SINGLE_CLASS_RE.fullmatch(part) for part in parts)


def read_css_block(text: str, open_index: int) -> tuple[str, int]:
    return_end = balanced_end(text, open_index, "{", "}")
    return text[open_index + 1 : return_end - 1], return_end


def skip_css_ws(text: str, index: int, end: int) -> int:
    while index < end:
        if text.startswith("/*", index):
            stop = text.find("*/", index + 2)
            index = end if stop < 0 else stop + 2
            continue
        if text[index].isspace():
            index += 1
            continue
        break
    return index


def scan_css_range(
    text: str,
    start: int,
    end: int,
    rel_path: str,
    in_keyframes: bool,
    findings: list[Finding],
) -> None:
    index = start
    while index < end:
        index = skip_css_ws(text, index, end)
        if index >= end:
            return
        if text[index] == "}":
            index += 1
            continue
        if text[index] == "@":
            match = re.match(r"@([A-Za-z-]+)", text[index:])
            if match is None:
                index += 1
                continue
            name = match.group(1).lower()
            cursor = index + match.end()
            cursor = skip_css_ws(text, cursor, end)
            if name == "apply" and not in_keyframes:
                semi = text.find(";", cursor)
                apply_end = end if semi < 0 else semi
                utilities = text[cursor:apply_end].strip()
                findings.append(
                    Finding(
                        path=rel_path,
                        line=line_at(text, index),
                        kind="tailwind-apply",
                        detail=f"@apply {utilities}".strip(),
                    )
                )
                index = end if semi < 0 else semi + 1
                continue
            if cursor < end and text[cursor] == "{":
                body, after = read_css_block(text, cursor)
                if name not in SKIP_AT_BLOCKS:
                    scan_css_range(
                        text,
                        cursor + 1,
                        after - 1,
                        rel_path,
                        in_keyframes or name == "keyframes",
                        findings,
                    )
                index = after
                continue
            semi = text.find(";", index)
            index = end if semi < 0 else semi + 1
            continue
        selector_start = index
        selector_chars: list[str] = []
        while index < end and text[index] != "{":
            if text[index] in ("'", '"'):
                stop = skip_string(text, index)
                selector_chars.append(text[index:stop])
                index = stop
                continue
            selector_chars.append(text[index])
            index += 1
        if index >= end or text[index] != "{":
            return
        selector = "".join(selector_chars).strip()
        body, after = read_css_block(text, index)
        if not in_keyframes:
            for apply_match in re.finditer(r"@apply\b([^;]*);", body):
                utilities = apply_match.group(1).strip()
                findings.append(
                    Finding(
                        path=rel_path,
                        line=line_at(text, index + 1 + apply_match.start()),
                        kind="tailwind-apply",
                        detail=f"@apply {utilities}".strip(),
                    )
                )
        if not in_keyframes and "{" not in body and single_class_selectors(selector):
            declarations = split_declarations(body)
            utilities: list[str] = []
            others = 0
            for prop, value in declarations:
                if prop.startswith("--"):
                    continue
                utility = utility_for(prop, value)
                if utility is None:
                    others += 1
                else:
                    utilities.append(utility)
            if utilities and others == 0:
                findings.append(
                    Finding(
                        path=rel_path,
                        line=line_at(text, selector_start),
                        kind="tailwind-utility-css",
                        detail=" ".join(utilities),
                    )
                )
            elif utilities and others > 0:
                findings.append(
                    Finding(
                        path=rel_path,
                        line=line_at(text, selector_start),
                        kind="tailwind-mixed-css",
                        detail=" ".join(utilities),
                        severity="review",
                    )
                )
        if not in_keyframes and "{" in body:
            scan_css_range(text, index + 1, after - 1, rel_path, False, findings)
        index = after


def dedupe(findings: list[Finding]) -> list[Finding]:
    seen: set[tuple[str, int, str, str, str]] = set()
    unique: list[Finding] = []
    for finding in findings:
        key = (finding.path, finding.line, finding.kind, finding.detail, finding.severity)
        if key in seen:
            continue
        seen.add(key)
        unique.append(finding)
    return unique


def scan_css(rel_path: str, text: str) -> list[Finding]:
    findings: list[Finding] = []
    scan_css_range(text, 0, len(text), rel_path, False, findings)
    return dedupe(findings)


def component_summary(detection: Detection) -> str:
    found: dict[str, str] = {}
    for pkg in detection.packages:
        for label, version in pkg.components.items():
            found.setdefault(label, version)
    if found:
        rendered = ", ".join(f"{name} {version}" for name, version in sorted(found.items()))
        return f"applicable ({rendered} declared)"
    if detection.has_component_file:
        return "uncertain (component files found, no React, Vue, Svelte, Solid, Preact, or Angular dependency)"
    return "not applicable"


def template_summary(detection: Detection, mode: str) -> str:
    if mode == "laravel":
        versions = sorted({pkg.laravel for pkg in detection.packages if pkg.laravel})
        return "applicable (laravel/framework " + ", ".join(versions) + " declared)"
    if mode == "roots":
        roots = sorted(item for pkg in detection.packages for item in pkg.roots)
        return "applicable (" + ", ".join(roots) + ")"
    if mode == "laravel+roots":
        return "applicable (Laravel and Roots/Sage packages declared)"
    if mode == "uncertain":
        return (
            "uncertain (Blade templates found, no Laravel or Roots package detected); "
            "Eloquent and DB query checks still run; WordPress template tags were not failed"
        )
    return "not applicable"


def tailwind_summary(detection: Detection) -> str:
    scoped = [pkg for pkg in detection.packages if package_uses_tailwind(pkg)]
    others = [
        pkg
        for pkg in detection.packages
        if package_other_styling(pkg) and not package_uses_tailwind(pkg)
    ]
    if not scoped and not others:
        return "not applicable (no Tailwind dependency, config, or detected entry)"
    parts: list[str] = []
    for pkg in scoped:
        where = pkg.rel or "."
        parts.append(f"{where}: {styling_label(pkg)}")
    for pkg in others:
        where = pkg.rel or "."
        parts.append(f"{where}: not applied ({styling_label(pkg)})")
    return "scoped (" + "; ".join(parts) + ")"


def git_stdout(root: str, args: list[str]) -> str | None:
    result = subprocess.run(
        ["git", "-C", root, *args],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout


def project_git_root(root: str) -> str | None:
    """Return root when that directory is its own git toplevel.

    A fixture or nested directory inside another repository is not a project
    git root. Baseline generation must not read the ancestor repository.
    """
    top = git_stdout(root, ["rev-parse", "--show-toplevel"])
    if top is None:
        return None
    if os.path.realpath(top.strip()) != os.path.realpath(root):
        return None
    return root


def parse_baseline(text: str) -> tuple[Counter[tuple[str, str, str]], list[Finding]]:
    counts: Counter[tuple[str, str, str]] = Counter()
    invalid: list[Finding] = []
    for index, raw in enumerate(text.splitlines(), start=1):
        stripped = raw.strip()
        if stripped == "" or stripped.startswith("#"):
            continue
        parts = raw.split("\t")
        if len(parts) != 3:
            invalid.append(
                Finding(
                    path=BASELINE_REL,
                    line=index,
                    kind="invalid-baseline",
                    detail="expected path, kind, and snippet separated by tabs",
                )
            )
            continue
        path, kind, snippet = (part.strip() for part in parts)
        if (
            kind not in KINDS
            or snippet == ""
            or path == ""
            or path.startswith("/")
            or ".." in path.split("/")
            or "*" in path
            or path.endswith("/")
        ):
            invalid.append(
                Finding(
                    path=BASELINE_REL,
                    line=index,
                    kind="invalid-baseline",
                    detail="whole-file, wildcard, and incomplete entries do not suppress findings",
                )
            )
            continue
        counts[(path, kind, normalize_snippet(snippet))] += 1
    return counts, invalid


def load_baseline(root: str) -> tuple[Counter[tuple[str, str, str]], list[Finding]]:
    path = os.path.join(root, BASELINE_REL)
    if not os.path.isfile(path):
        return Counter(), []
    text = read_text(path)
    if text is None:
        return Counter(), [
            Finding(
                path=BASELINE_REL,
                line=1,
                kind="invalid-baseline",
                detail="baseline file could not be read",
            )
        ]
    return parse_baseline(text)


def apply_policy(findings: list[Finding], lines: list[str], baseline: Counter[tuple[str, str, str]]) -> tuple[list[Finding], int]:
    kept: list[Finding] = []
    baselined = 0
    file_marker = file_allow_architecture(lines)
    if file_marker is not None:
        kept.append(
            Finding(
                path="",
                line=file_marker,
                kind="invalid-suppression",
                detail="guardrail-allow-file cannot exempt architecture findings",
            )
        )
    for finding in findings:
        if finding.severity == "review":
            kept.append(finding)
            continue
        allowance = line_allowance(lines, finding.line - 1)
        if allowance == "allow":
            continue
        key = (finding.path, finding.kind, normalize_snippet(lines[finding.line - 1] if finding.line else ""))
        if finding.kind in KINDS and baseline[key] > 0:
            baseline[key] -= 1
            baselined += 1
            continue
        if allowance == "reject":
            finding = Finding(
                path=finding.path,
                line=finding.line,
                kind=finding.kind,
                detail=finding.detail + "; nearby guardrail-allow-architecture marker was rejected",
            )
        kept.append(finding)
    return kept, baselined


ADVICE = {
    "template-query": "Move the query or field read to the controller, composer, presenter, service, or this framework's equivalent preparation layer.",
    "template-persistence": "Move persistence and side effects out of the template.",
    "template-preparation": "Move data preparation out of the template. Conditions, loops, formatting, and class selection may stay.",
    "template-orchestration": "Move service location and orchestration out of the template.",
    "tailwind-apply": "Compose those utilities in the markup. @apply is not a way to relocate utility styling into a semantic class.",
    "tailwind-utility-css": "Compose the named utilities in the markup instead of a custom class.",
    "tailwind-mixed-css": "Part of this class maps to utilities. Keep the class only if the remaining CSS is a concrete limitation.",
    "invalid-suppression": "Put guardrail-allow-architecture on the finding line or the line above it, with the concrete limitation.",
    "invalid-baseline": "Fix or remove the entry. It did not suppress any finding.",
}


def format_finding(finding: Finding) -> str:
    label = "REVIEW" if finding.severity == "review" else "FAIL"
    advice = ADVICE.get(finding.kind, "Fix the finding or record a narrow, justified exception.")
    return (
        f"{label}  {finding.path}:{finding.line}: {finding.kind}: {finding.detail}\n"
        f"      {advice}"
    )


def scan_file(rel_path: str, text: str, detection: Detection, mode: str) -> tuple[list[Finding], str | None]:
    if is_component_file(rel_path):
        return [], None
    findings: list[Finding] = []
    skip_reason = None
    if is_template(rel_path) and mode != "none":
        findings.extend(scan_template(rel_path, text, mode))
    if rel_path.lower().endswith((".css", ".scss")):
        in_scope, reason = tailwind_scope(detection, rel_path, text)
        if in_scope:
            findings.extend(scan_css(rel_path, text))
        else:
            skip_reason = reason
    return findings, skip_reason


def rel_from_root(root: str, raw: str) -> str:
    if os.path.isabs(raw):
        return os.path.relpath(raw, root).replace("\\", "/")
    return raw.replace("\\", "/")


def collect_paths(root: str, explicit: list[str] | None, scan_all: bool) -> tuple[list[str], str]:
    if scan_all:
        return sorted(iter_all_files(root)), "all in-scope files"
    paths: list[str] = []
    for raw in explicit or []:
        rel = rel_from_root(root, raw)
        if path_is_in_scope(rel) or is_template(rel) or is_component_file(rel):
            paths.append(rel)
    return paths, "explicit files"


def print_header(root: str, detection: Detection, mode: str, scope: str, count: int) -> None:
    print("=== Stack-native architecture ===")
    print(f"Target: {root}")
    print(f"Scope: {scope} ({count} files)")
    print("")
    print("Profiles:")
    print(f"  template: {template_summary(detection, mode)}")
    print(f"  component: {component_summary(detection)}")
    print(f"  tailwind: {tailwind_summary(detection)}")
    print("")


def print_coverage(
    detection: Detection,
    mode: str,
    template_files: int,
    component_files: int,
    css_checked: int,
    css_skipped: list[str],
) -> None:
    print("Checks:")
    if mode == "none":
        print("  template-query: not applicable")
        print("  template-preparation: not applicable")
    elif template_files == 0:
        print("  template-query: no template files in this scan")
        print("  template-preparation: no template files in this scan")
    else:
        print(f"  template-query: executed ({template_files} file(s))")
        print(f"  template-preparation: executed ({template_files} file(s))")
    if css_checked:
        print(f"  tailwind-custom-css: executed ({css_checked} file(s))")
    elif "not applicable" in tailwind_summary(detection):
        print("  tailwind-custom-css: not applicable")
    else:
        print("  tailwind-custom-css: no in-scope CSS files in this scan")
    if component_files:
        print(
            f"  component-mvc: not applied ({component_files} component file(s); "
            "MVC template restrictions were not used)"
        )
    else:
        print("  component-mvc: not applied (no component files in this scan)")
    print("")
    print("Coverage:")
    if mode == "uncertain":
        print("  WordPress template tags: not failed, because the view convention is uncertain")
    if detection.unsupported_templates:
        suffixes = ", ".join(sorted(detection.unsupported_templates))
        print(f"  Unsupported template types present and not checked: {suffixes}")
    if css_skipped:
        unique = sorted(set(css_skipped))
        print(f"  Tailwind custom-CSS check skipped {len(css_skipped)} file(s): {'; '.join(unique)}")
    if mode != "uncertain" and not detection.unsupported_templates and not css_skipped:
        print("  No additional unsupported template or styling scope in this scan")
    print("")


def print_closer(failures: int, reviews: int) -> None:
    print("This check does not prove architecture compliance.")
    print("Lint, tests, build, and a zero-finding result do not prove it either.")
    if failures:
        print("A failed architecture check is not a green completion.")
        print("Do not add a suppression or baseline entry merely to make this command pass.")
    elif reviews:
        print("Review items are not failures. The architecture completion review must account for them.")
    else:
        print(
            "When this task changes views, components, data preparation, or styling, "
            "complete the architecture review."
        )
    print("")


def run_check(root: str, rel_paths: list[str], scope: str) -> int:
    detection = detect(root)
    mode = template_mode(detection)
    print_header(root, detection, mode, scope, len(rel_paths))
    counts = {"template": 0, "component": 0, "css": 0}
    skipped: list[str] = []
    baseline, invalid_baseline = load_baseline(root)
    baselined = 0
    kept: list[Finding] = []
    for rel in rel_paths:
        full = os.path.join(root, rel)
        if not os.path.isfile(full):
            print(f"NOTE  {rel}: skipped (not a file)")
            continue
        text = read_text(full)
        if text is None:
            print(f"NOTE  {rel}: skipped (unreadable or not UTF-8)")
            continue
        if len(text) > MAX_FILE_CHARS:
            print(f"NOTE  {rel}: skipped (file exceeds {MAX_FILE_CHARS} characters)")
            continue
        if is_template(rel):
            counts["template"] += 1
        if is_component_file(rel):
            counts["component"] += 1
        if rel.lower().endswith((".css", ".scss")):
            in_scope, reason = tailwind_scope(detection, rel, text)
            if in_scope:
                counts["css"] += 1
            else:
                skipped.append(f"{rel}: {reason}")
        lines = text.splitlines() or [""]
        file_findings, _skip = scan_file(rel, text, detection, mode)
        reviewed, used = apply_policy(file_findings, lines, baseline)
        baselined += used
        for finding in reviewed:
            if finding.path == "":
                finding = Finding(
                    path=rel,
                    line=finding.line,
                    kind=finding.kind,
                    detail=finding.detail,
                    severity=finding.severity,
                )
            kept.append(finding)
    kept.extend(invalid_baseline)
    print_coverage(detection, mode, counts["template"], counts["component"], counts["css"], skipped)
    if baselined:
        print(f"Baselined: {baselined} existing finding(s) matched an explicit baseline entry.")
    scanned_paths = set(rel_paths)
    stale = [
        (path, kind, snippet)
        for (path, kind, snippet), count in baseline.items()
        if count > 0 and path in scanned_paths
    ]
    for path, kind, snippet in stale:
        print(f"NOTE  stale baseline entry not matched: {path} {kind} {snippet}")
    if baselined or stale:
        print("")
    failures = [finding for finding in kept if finding.severity != "review"]
    reviews = [finding for finding in kept if finding.severity == "review"]
    if not rel_paths and not failures:
        print("No architecture-relevant files in this scan.")
        print("")
    for finding in failures + reviews:
        print(format_finding(finding))
        print("")
    print(f"Failures: {len(failures)}")
    print(f"Review items: {len(reviews)}")
    print("")
    print_closer(len(failures), len(reviews))
    return 1 if failures else 0


def findings_for_text(rel: str, text: str, detection: Detection, mode: str) -> list[Finding]:
    file_findings, _skip = scan_file(rel, text, detection, mode)
    lines = text.splitlines() or [""]
    # Baseline generation records unsuppressed committed findings, including
    # ones a marker would hide, so a marker is not required in old code.
    recorded: list[Finding] = []
    for finding in file_findings:
        if finding.severity == "review" or finding.kind not in KINDS:
            continue
        if line_allowance(lines, finding.line - 1) == "allow":
            continue
        snippet = normalize_snippet(lines[finding.line - 1] if finding.line <= len(lines) else finding.detail)
        recorded.append(
            Finding(path=rel, line=finding.line, kind=finding.kind, detail=snippet)
        )
    return recorded


def write_baseline(root: str) -> int:
    if project_git_root(root) is None:
        print(
            "Error: --write-architecture-baseline requires TARGET to be its own "
            "git repository, so uncommitted violations are not baselined and an "
            "ancestor repository is not read.",
            file=sys.stderr,
        )
        return 2
    detection = detect(root)
    mode = template_mode(detection)
    tracked = git_stdout(root, ["ls-files"])
    if tracked is None:
        print("Error: git ls-files failed.", file=sys.stderr)
        return 2
    entries: list[tuple[str, int, str, str]] = []
    skipped_untracked: list[str] = []
    working_only: list[Finding] = []
    for rel in sorted(iter_all_files(root)):
        head = git_stdout(root, ["show", f"HEAD:{rel}"])
        if head is None:
            skipped_untracked.append(rel)
            continue
        if len(head) > MAX_FILE_CHARS:
            print(f"NOTE  {rel}: skipped (HEAD file exceeds {MAX_FILE_CHARS} characters)")
            continue
        for finding in findings_for_text(rel, head, detection, mode):
            entries.append((rel, finding.line, finding.kind, finding.detail))
        full = os.path.join(root, rel)
        if not os.path.isfile(full):
            continue
        working = read_text(full)
        if working is None or working == head:
            continue
        head_keys = {
            (item.line, item.kind, item.detail)
            for item in findings_for_text(rel, head, detection, mode)
        }
        for finding in findings_for_text(rel, working, detection, mode):
            key = (finding.line, finding.kind, finding.detail)
            if key not in head_keys:
                working_only.append(finding)
    lines = [
        "# Architecture baseline. One finding per line.",
        "# Format: path<TAB>kind<TAB>snippet",
        "# Written from committed files by check-guardrails.sh --write-architecture-baseline.",
        "# Do not add wildcards, bare paths, or new violations here to make a check pass.",
    ]
    for path, _line, kind, snippet in sorted(entries, key=lambda item: (item[0], item[1], item[2], item[3])):
        lines.append(f"{path}\t{kind}\t{snippet}")
    destination = os.path.join(root, BASELINE_REL)
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    with open(destination, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")
    print(f"Wrote {BASELINE_REL} ({len(entries)} committed finding(s)).")
    if skipped_untracked:
        print(f"Skipped {len(skipped_untracked)} in-scope path(s) that are not in HEAD.")
    if working_only:
        print(f"Working tree has {len(working_only)} finding(s) that were not baselined:")
        for finding in working_only:
            print(f"  {finding.path}:{finding.line}: {finding.kind}: {finding.detail}")
    print("Review the file before committing it. This command does not fix violations.")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check stack-native architecture findings.")
    parser.add_argument("root")
    parser.add_argument("--files", nargs="*", default=None)
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--write-baseline", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    root = os.path.abspath(args.root)
    if not os.path.isdir(root):
        print(f"Error: project root is not a directory: {root}", file=sys.stderr)
        return 2
    if args.write_baseline:
        if args.all or args.files is not None:
            print(
                "Error: --write-architecture-baseline inventories HEAD and does not take a file subset.",
                file=sys.stderr,
            )
            return 2
        return write_baseline(root)
    if args.all:
        rel_paths, scope = collect_paths(root, None, True)
    elif args.files is not None:
        rel_paths, scope = collect_paths(root, args.files, False)
    else:
        print(
            "Error: pass --files or --all (the shell wrapper supplies git-changed files).",
            file=sys.stderr,
        )
        return 2
    return run_check(root, rel_paths, scope)


if __name__ == "__main__":
    sys.exit(main())
