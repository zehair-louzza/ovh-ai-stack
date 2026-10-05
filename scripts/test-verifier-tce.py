"""Tests d'archivage : aucune suppression hors des deux anciens répertoires."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("verifier", Path(__file__).with_name("verifier-tce.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
OLD = "extraire-demande-travaux"


class CleanupTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def write(self, directory, content=None):
        directory.mkdir(parents=True, exist_ok=True)
        path = directory / "SKILL.md"
        path.write_text(content or f"---\nname: {OLD}\n---\nInstructions.", encoding="utf-8")
        return path

    def test_known_leaf_only(self):
        path = self.write(self.root / OLD)
        self.assertEqual(module.obsolete_leaf_name(path, self.root, {OLD}), OLD)

    def test_root_never_archived(self):
        path = self.write(self.root)
        with self.assertRaises(SystemExit):
            module.obsolete_leaf_name(path, self.root, {OLD})

    def test_collective_never_archived(self):
        path = self.write(self.root / OLD)
        self.write(self.root / OLD / "other")
        with self.assertRaises(SystemExit):
            module.obsolete_leaf_name(path, self.root, {OLD})

    def test_body_reference_is_not_metadata(self):
        path = self.write(self.root / "keep", f"---\nname: keep\n---\nExemple:\nname: {OLD}\n")
        self.assertIsNone(module.obsolete_leaf_name(path, self.root, {OLD}))

    def test_other_directory_not_archived(self):
        path = self.write(self.root / "shared")
        with self.assertRaises(SystemExit):
            module.obsolete_leaf_name(path, self.root, {OLD})

    def test_smoke_schema_is_separate_from_model_quality(self):
        value = {"quantite_ballon": 1, "capacite_l": 150,
                 "fournir_evier": True, "quantite_prises": None}
        # Boolean true is structurally valid but semantically wrong for the
        # synthetic example; it must be reported, not mistaken for an outage.
        self.assertTrue(module.smoke_schema_valid(value))
        value["quantite_ballon"] = True
        self.assertFalse(module.smoke_schema_valid(value))

    def test_smoke_rejects_unknown_fields_and_text(self):
        self.assertFalse(module.smoke_schema_valid({"prix": 10}))
        value = {"quantite_ballon": "1", "capacite_l": 150,
                 "fournir_evier": False, "quantite_prises": None}
        self.assertFalse(module.smoke_schema_valid(value))


if __name__ == "__main__":
    unittest.main()
