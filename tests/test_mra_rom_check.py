import gzip
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "other_authors" / "mra_rom_check.sh"


def mra(name, setname, bootleg=""):
    bootleg_xml = "<bootleg>{}</bootleg>".format(bootleg) if bootleg else ""
    return "<misterromdescription><name>{}</name>{}<setname>{}</setname><rbf>Test</rbf><rom></rom></misterromdescription>".format(name, bootleg_xml, setname)


class MraRomCheckTests(unittest.TestCase):
    def run_layout(self, files, descriptions, parents):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            arcade = root / "_Arcade"
            arcade.mkdir()
            for name, contents in files.items():
                (arcade / name).write_text(contents, encoding="utf-8")
            parent_map = root / "parents.json.gz"
            with gzip.open(parent_map, "wt", encoding="utf-8") as handle:
                json.dump({"descriptions": descriptions, "parents": parents}, handle)
            return subprocess.run(
                [sys.executable, str(SCRIPT), "--layout-only", "--mra-folder", str(arcade), "--parent-map", str(parent_map)],
                cwd=root, text=True, encoding="utf-8", errors="replace", stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            )

    def test_mismatched_xml_case_is_rejected(self):
        result = self.run_layout(
            {"Bad.mra": "<misterromdescription><name>Bad</name><setname>bad</setname><rom></ROM></misterromdescription>"},
            {"bad": "Bad"}, {},
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("well_formed_xml", result.stdout)
        self.assertIn("mismatched tag", result.stdout)

    def test_duplicate_and_bootleg_are_reported(self):
        result = self.run_layout(
            {"Parent.mra": mra("Parent", "parent"), "Bootleg.mra": mra("Parent (bootleg)", "boot", "yes")},
            {"parent": "Parent", "boot": "Parent (bootleg)"}, {"boot": "parent"},
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("one_top_level_mra_per_game", result.stdout)
        self.assertIn("parent_over_bootleg", result.stdout)

    def test_clean_layout_passes(self):
        result = self.run_layout({"Parent.mra": mra("Parent", "parent")}, {"parent": "Parent"}, {})
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("MRA layout violations: 0", result.stdout)


if __name__ == "__main__":
    unittest.main()
