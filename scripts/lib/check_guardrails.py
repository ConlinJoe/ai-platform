#!/usr/bin/env python3
"""Scan application sources for em-dash copy and arbitrary Tailwind utilities."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections.abc import Iterable
from dataclasses import dataclass
from functools import lru_cache

SKIP_DIR_NAMES = {
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
    "design-reviews",
    "storage",
}

SKIP_PATH_PARTS = {
    "public/build",
    "public/hot",
    "public/vendor",
    "bootstrap/cache",
}

INCLUDED_SUFFIXES = (
    ".blade.php",
    ".html",
    ".htm",
    ".vue",
    ".jsx",
    ".tsx",
    ".svelte",
    ".php",
    ".css",
    ".scss",
    ".js",
    ".ts",
    ".mjs",
    ".cjs",
    ".twig",
    ".mdx",
    ".njk",
)

LANG_JSON_HINTS = ("/lang/", "/resources/lang/", "/resources/js/lang/")

UTILITY_PREFIXES = tuple(
    sorted(
        (
            "text",
            "leading",
            "tracking",
            "indent",
            "p",
            "px",
            "py",
            "pt",
            "pb",
            "pl",
            "pr",
            "ps",
            "pe",
            "m",
            "mx",
            "my",
            "mt",
            "mb",
            "ml",
            "mr",
            "ms",
            "me",
            "gap",
            "gap-x",
            "gap-y",
            "space-x",
            "space-y",
            "w",
            "h",
            "size",
            "min-w",
            "max-w",
            "min-h",
            "max-h",
            "inset",
            "inset-x",
            "inset-y",
            "top",
            "right",
            "bottom",
            "left",
            "start",
            "end",
            "scroll-m",
            "scroll-mx",
            "scroll-my",
            "scroll-mt",
            "scroll-mb",
            "scroll-ml",
            "scroll-mr",
            "scroll-ms",
            "scroll-me",
            "scroll-p",
            "scroll-px",
            "scroll-py",
            "scroll-pt",
            "scroll-pb",
            "scroll-pl",
            "scroll-pr",
            "scroll-ps",
            "scroll-pe",
        ),
        key=len,
        reverse=True,
    )
)

PREFIX_PATTERN = "|".join(re.escape(prefix) for prefix in UTILITY_PREFIXES)
ARBITRARY_RE = re.compile(
    rf"(?:^|[^A-Za-z0-9_-])(?:[A-Za-z0-9@.&|\[\]_/-]+:)*({PREFIX_PATTERN})-\[([^\]]+)\]"
)
EM_DASH_RE = re.compile(
    "(?:\u2014|&mdash;|&#8212;|&#x2014;|\\\\u2014|\\\\u\\{2014\\})",
    re.IGNORECASE,
)
ALLOW_EM_DASH_RE = re.compile(r"guardrail-allow-em-dash")
ALLOW_ARBITRARY_RE = re.compile(r"guardrail-allow-arbitrary")
ALLOW_FILE_RE = re.compile(r"guardrail-allow-file:\s*([^\n]+)", re.IGNORECASE)


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    kind: str
    detail: str


@lru_cache(maxsize=None)
def installed_dependency_paths(package_root: str, project_root: str) -> tuple[str, ...]:
    """Read ownership metadata without executing Composer or assuming WP paths.

    Invalid metadata leaves sources in scope. Install paths in installed.json
    are relative to vendor/composer, not to the package manifest.
    """
    paths: set[str] = set()

    def add(raw: object, relative_to: str) -> None:
        if not isinstance(raw, str) or not raw.strip():
            return
        absolute = os.path.abspath(os.path.join(relative_to, raw))
        try:
            if os.path.commonpath((absolute, project_root)) != project_root:
                return
        except ValueError:
            return
        if absolute != project_root:
            paths.add(absolute)

    def load(path: str) -> object:
        try:
            with open(path, encoding="utf-8") as handle:
                return json.load(handle)
        except (OSError, ValueError, UnicodeDecodeError):
            return None

    manifest = load(os.path.join(package_root, "composer.json"))
    if isinstance(manifest, dict):
        extra = manifest.get("extra")
        if isinstance(extra, dict):
            add(extra.get("wordpress-install-dir"), package_root)

    config = manifest.get("config", {}) if isinstance(manifest, dict) else {}
    vendor_dir = config.get("vendor-dir", "vendor") if isinstance(config, dict) else "vendor"
    if not isinstance(vendor_dir, str) or not vendor_dir.strip():
        vendor_dir = "vendor"
    metadata_dir = os.path.join(package_root, vendor_dir, "composer")
    installed = load(os.path.join(metadata_dir, "installed.json"))
    packages = installed.get("packages", []) if isinstance(installed, dict) else installed
    if isinstance(packages, list):
        for package in packages:
            if isinstance(package, dict):
                add(package.get("install-path"), metadata_dir)
    return tuple(sorted(paths))


def path_is_skipped(rel_path: str, root: str | None = None) -> bool:
    parts = rel_path.replace("\\", "/").split("/")
    if any(part in SKIP_DIR_NAMES for part in parts):
        return True
    normalized = "/".join(parts)
    if any(normalized == token or normalized.startswith(token + "/") for token in SKIP_PATH_PARTS):
        return True
    if root is not None:
        project_root = os.path.abspath(root)
        full = os.path.abspath(os.path.join(project_root, normalized))
        if os.path.commonpath((full, project_root)) != project_root:
            return True
        # Also support independent Composer packages inside a monorepo.
        current = project_root
        directories = normalized.split("/")[:-1]
        for part in ["", *directories]:
            current = os.path.join(current, part)
            for dependency in installed_dependency_paths(current, project_root):
                if full == dependency or full.startswith(dependency + os.sep):
                    return True
    return False


def path_is_in_scope(rel_path: str, root: str | None = None) -> bool:
    if path_is_skipped(rel_path, root):
        return False
    lowered = rel_path.replace("\\", "/").lower()
    if lowered.endswith(".json") and any(hint in f"/{lowered}" for hint in LANG_JSON_HINTS):
        return True
    return any(lowered.endswith(suffix) for suffix in INCLUDED_SUFFIXES)


def read_text(path: str) -> str | None:
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except (OSError, UnicodeDecodeError):
        return None


def file_level_allows(lines: list[str]) -> tuple[bool, bool]:
    allow_em = False
    allow_arbitrary = False
    for line in lines[:30]:
        match = ALLOW_FILE_RE.search(line)
        if match is None:
            continue
        payload = match.group(1).lower()
        if "em-dash" in payload or "emdash" in payload:
            allow_em = True
        if "arbitrary" in payload:
            allow_arbitrary = True
    return allow_em, allow_arbitrary


def line_is_allowed(lines: list[str], index: int, pattern: re.Pattern[str]) -> bool:
    current = lines[index]
    previous = lines[index - 1] if index > 0 else ""
    return bool(pattern.search(current) or pattern.search(previous))


def scan_text(rel_path: str, text: str, *, check_arbitrary: bool = True) -> list[Finding]:
    lines = text.splitlines()
    allow_em_file, allow_arbitrary_file = file_level_allows(lines)
    findings: list[Finding] = []

    for index, line in enumerate(lines):
        line_no = index + 1
        if not allow_em_file and not line_is_allowed(lines, index, ALLOW_EM_DASH_RE):
            for match in EM_DASH_RE.finditer(line):
                findings.append(
                    Finding(
                        path=rel_path,
                        line=line_no,
                        kind="em-dash",
                        detail=match.group(0),
                    )
                )
        if not check_arbitrary or allow_arbitrary_file or line_is_allowed(lines, index, ALLOW_ARBITRARY_RE):
            continue
        for match in ARBITRARY_RE.finditer(line):
            token = f"{match.group(1)}-[{match.group(2)}]"
            findings.append(
                Finding(
                    path=rel_path,
                    line=line_no,
                    kind="arbitrary-tailwind",
                    detail=token,
                )
            )
    return findings


def iter_all_files(root: str) -> Iterable[str]:
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [name for name in dirnames if name not in SKIP_DIR_NAMES]
        rel_dir = os.path.relpath(dirpath, root)
        if rel_dir != "." and path_is_skipped(rel_dir, root):
            dirnames[:] = []
            continue
        for filename in filenames:
            full = os.path.join(dirpath, filename)
            rel = os.path.relpath(full, root)
            if path_is_in_scope(rel, root):
                yield rel.replace("\\", "/")


def format_finding(finding: Finding) -> str:
    if finding.kind == "em-dash":
        return (
            f"FAIL  {finding.path}:{finding.line}: generated copy contains an em dash "
            f"({finding.detail})\n"
            "      Rewrite naturally, or keep required source punctuation with "
            "`guardrail-allow-em-dash` on this line or the previous line."
        )
    return (
        f"FAIL  {finding.path}:{finding.line}: arbitrary Tailwind utility "
        f"`{finding.detail}`\n"
        "      Prefer a standard utility or theme token. For a genuine one-off, "
        "add `guardrail-allow-arbitrary` on this line or the previous line."
    )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check public-facing sources for em dashes and arbitrary Tailwind utilities."
    )
    parser.add_argument("root", help="Project root to scan")
    parser.add_argument(
        "--files",
        nargs="*",
        default=None,
        help="Specific paths relative to the project root (or absolute)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Scan all in-scope files under the project root",
    )
    return parser.parse_args(argv)


def resolve_rel_path(root: str, raw: str) -> str:
    if os.path.isabs(raw):
        return os.path.relpath(raw, root)
    return raw


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    root = os.path.abspath(args.root)
    if not os.path.isdir(root):
        print(f"Error: project root is not a directory: {root}", file=sys.stderr)
        return 2

    if args.all:
        rel_paths = sorted(iter_all_files(root))
        scope = "all in-scope files"
    elif args.files is not None:
        rel_paths = []
        for raw in args.files:
            rel = resolve_rel_path(root, raw).replace("\\", "/")
            if path_is_in_scope(rel, root):
                rel_paths.append(rel)
        scope = "explicit files"
    else:
        print(
            "Error: pass --files or --all (the shell wrapper supplies git-changed files).",
            file=sys.stderr,
        )
        return 2

    print("=== Copy and Tailwind guardrails ===")
    print(f"Target: {root}")
    print(f"Scope: {scope} ({len(rel_paths)} files)")
    print("")

    if not rel_paths:
        print("OK    No applicable files")
        print("")
        print("Failures: 0")
        return 0

    from stack_scope import detect, tailwind_scope

    detection = detect(root)
    findings: list[Finding] = []
    scanned = 0
    applicable = 0
    not_applied: list[str] = []
    uncertain: list[str] = []
    for rel in rel_paths:
        full = os.path.join(root, rel)
        if not os.path.isfile(full):
            continue
        text = read_text(full)
        if text is None:
            continue
        scanned += 1
        status, reason = tailwind_scope(detection, rel, text)
        check_arbitrary = status == "applicable"
        if status == "applicable":
            applicable += 1
        elif status == "uncertain":
            uncertain.append(f"{rel}: {reason}")
        else:
            not_applied.append(f"{rel}: {reason}")
        findings.extend(scan_text(rel, text, check_arbitrary=check_arbitrary))

    print(
        "Tailwind arbitrary utilities: "
        f"applicable {applicable}, not applied {len(not_applied)}, uncertain {len(uncertain)}"
    )
    print("Em dashes are checked in every in-scope file. Uncertain Tailwind scope does not apply Tailwind rules.")
    if not_applied:
        print("Tailwind rules not applied:")
        for note in not_applied:
            print(f"  {note}")
    if uncertain:
        print("Uncertain Tailwind scope (rules not applied):")
        for note in uncertain:
            print(f"  {note}")
    print("")

    if not findings:
        print(f"OK    {scanned} file(s) scanned, no violations")
        print("")
        print("Failures: 0")
        return 0

    for finding in findings:
        print(format_finding(finding))
        print("")
    print(f"Failures: {len(findings)}")
    print("")
    print("A failed guardrail check is not a green completion.")
    print("Fix the violation, or use the documented exception marker and explain why.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
