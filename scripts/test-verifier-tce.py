"""Tests d'archivage : aucune suppression hors des deux anciens répertoires."""
import importlib.util
import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

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


class ModelSelectionTest(unittest.TestCase):
    def run_smoke(self, installed, returned_model="gpt-oss:20b", provider="custom:ollama"):
        observed = []

        def response(request, **kwargs):
            url = request if isinstance(request, str) else request.full_url
            if url.endswith("/api/tags"):
                data = {"models": [{"name": model} for model in installed]}
            elif url.endswith("/v1/chat/completions"):
                observed.append(json.loads(request.data))
                data = {"model": "hermes-agent",
                        "runtime": {"provider": provider, "model": returned_model},
                        "choices": [{"message": {"content": json.dumps({
                    "quantite_ballon": 1, "capacite_l": 150,
                    "fournir_evier": False, "quantite_prises": None,
                })}}]}
                if returned_model is None:
                    del data["runtime"]
            else:
                # Stop before the independent SaaS health check, after inference.
                raise RuntimeError("health-reached")
            return io.BytesIO(json.dumps(data).encode())

        with patch("sys.argv", ["verifier-tce.py", "--files", "--smoke"]), \
                patch.dict(module.os.environ, {"API_SERVER_KEY": "synthetic-test-key"}), \
                patch.object(module.urllib.request, "urlopen", side_effect=response), \
                contextlib.redirect_stdout(io.StringIO()):
            try:
                module.main()
            except RuntimeError as exc:
                if str(exc) != "health-reached":
                    raise
        return observed

    def test_missing_gpt_model_stops_before_inference(self):
        with self.assertRaisesRegex(SystemExit, "modele_requis_absent=gpt-oss:20b"):
            self.run_smoke(["qwen2.5:7b"])

    def test_gpt_is_requested_with_low_effort(self):
        payload, = self.run_smoke(["gpt-oss:20b"])
        self.assertEqual(payload["model"], "gpt-oss:20b")
        self.assertEqual(payload["model_options"]["reasoning_effort"], "low")
        self.assertEqual(payload["response_format"]["type"], "json_schema")

    def test_different_returned_model_is_fatal(self):
        with self.assertRaisesRegex(SystemExit, "runtime_modele_inattendu"):
            self.run_smoke(["gpt-oss:20b"], returned_model="qwen2.5:7b")

    def test_missing_optional_runtime_is_not_a_model_assertion(self):
        with patch("builtins.print") as output:
            self.run_smoke(["gpt-oss:20b"], returned_model=None)
        output.assert_any_call(
            "tce_v4 runtime_metadata=indisponible identite_reponse_non_attestee", flush=True)

    def test_custom_provider_canonical_name_is_accepted(self):
        self.assertEqual(len(self.run_smoke(["gpt-oss:20b"], provider="custom")), 1)

    def test_other_provider_is_rejected(self):
        with self.assertRaisesRegex(SystemExit, "runtime_modele_inattendu"):
            self.run_smoke(["gpt-oss:20b"], provider="custom:mistral")


if __name__ == "__main__":
    unittest.main()
