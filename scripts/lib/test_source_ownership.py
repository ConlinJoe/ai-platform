#!/usr/bin/env python3
"""Guardrail ownership regressions, using only temporary fixture projects."""

import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from check_guardrails import installed_dependency_paths, iter_all_files, path_is_in_scope
from stack_scope import detect


HARNESS = Path(__file__).resolve().parents[2]


class SourceOwnershipTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.write("composer.json", json.dumps({
            "require": {"roots/acorn": "^6"},
            "extra": {"wordpress-install-dir": "public/wp"},
        }))
        self.write("package.json", '{"dependencies":{"tailwindcss":"^4"}}')
        self.installed = "vendor/composer/installed.json"
        self.write(self.installed, json.dumps({"packages": [{
            "name": "johnbillion/query-monitor",
            "install-path": "../../public/content/plugins/query-monitor",
        }]}))
        self.owned = [
            "public/content/plugins/luxterra-blocks/plugin.php",
            "public/content/themes/radicle/index.blade.php",
            "public/content/mu-plugins/00-acorn-boot.php",
            "resources/views/page.blade.php",
            "public/wp-custom/page.php",
            "public/content/plugins/query-monitor-custom/plugin.php",
        ]
        self.external = [
            "public/wp/index.php",
            "public/content/plugins/query-monitor/plugin.php",
            "design-reviews/comp/index.html",
        ]
        for name in self.owned + self.external:
            self.write(name, "<p>Fixture — copy</p>\n")

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def scan(self, *args):
        return subprocess.run(
            [str(HARNESS / "scripts/check-guardrails.sh"), str(self.root), *args],
            capture_output=True, text=True,
        )

    def test_full_scan_preserves_first_party_and_omits_dependencies(self):
        files = set(iter_all_files(str(self.root)))
        for name in self.owned:
            self.assertIn(name, files)
        for name in self.external:
            self.assertNotIn(name, files)
        result = self.scan("--all")
        self.assertEqual(result.returncode, 1, result.stdout)
        for name in self.owned:
            self.assertIn(f"FAIL  {name}:1:", result.stdout)
        for name in self.external:
            self.assertNotIn(f"FAIL  {name}:", result.stdout)

    def test_explicit_paths_do_not_bypass_either_scanner(self):
        # Query and utility violations must not leak through the architecture
        # scanner's special handling of explicitly supplied Blade paths.
        for name in self.external:
            self.write(name, "@php\n$x = Estate::where('active', true)->get();\n@endphp\n<p>—</p>")
        self.write("design-reviews/comp/test.blade.php", "{{ Estate::where('active', true)->get() }}")
        result = self.scan("--files", *self.external, "design-reviews/comp/test.blade.php")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn("FAIL ", result.stdout)
        result = self.scan("--files", *self.owned)
        self.assertEqual(result.returncode, 1, result.stdout)
        for name in self.owned:
            self.assertIn(f"FAIL  {name}:1:", result.stdout)

    def test_dependency_manifests_do_not_select_framework_profiles(self):
        self.write("public/wp/composer.json", '{"require":{"laravel/framework":"^99"}}')
        self.write("public/content/plugins/query-monitor/package.json", '{"dependencies":{"react":"^99"}}')
        self.write("design-reviews/comp/package.json", '{"dependencies":{"bootstrap":"^5"}}')
        packages = {package.rel for package in detect(str(self.root)).packages}
        self.assertEqual(packages, {""})

    def test_v1_metadata_and_nonstandard_core_directory(self):
        self.write("composer.json", '{"extra":{"wordpress-install-dir":"web/core"}}')
        self.write(self.installed, '[{"install-path":"../../web/plugins/vendor-plugin"}]')
        self.write("web/core/index.php", "—")
        self.write("web/plugins/vendor-plugin/plugin.php", "—")
        installed_dependency_paths.cache_clear()
        self.assertFalse(path_is_in_scope("web/core/index.php", str(self.root)))
        self.assertFalse(path_is_in_scope("web/plugins/vendor-plugin/plugin.php", str(self.root)))

    def test_invalid_and_outside_metadata_cannot_hide_application(self):
        self.write("composer.json", '{"extra":{"wordpress-install-dir":"."}}')
        self.write(self.installed, '{"packages":[{"install-path":"../.."},{"install-path":"../../../outside"}]}')
        installed_dependency_paths.cache_clear()
        self.assertTrue(path_is_in_scope(self.owned[0], str(self.root)))
        self.write(self.installed, "{broken")
        installed_dependency_paths.cache_clear()
        self.assertTrue(path_is_in_scope(self.owned[0], str(self.root)))
        self.assertTrue(path_is_in_scope(self.external[1], str(self.root)))

    def test_nested_package_with_custom_vendor_directory(self):
        self.write("packages/cms/composer.json", '{"config":{"vendor-dir":"deps"}}')
        self.write("packages/cms/deps/composer/installed.json", '{"packages":[{"install-path":"../../web/plugin"}]}')
        self.write("packages/cms/web/plugin/a.php", "—")
        self.write("packages/cms/web/custom/a.php", "—")
        self.assertFalse(path_is_in_scope("packages/cms/web/plugin/a.php", str(self.root)))
        self.assertTrue(path_is_in_scope("packages/cms/web/custom/a.php", str(self.root)))


if __name__ == "__main__":
    unittest.main()
