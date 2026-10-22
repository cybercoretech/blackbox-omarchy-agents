import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_PROVIDERS = {
    "claude", "codex", "fireworks", "copilot", "antigravity",
    "cursor", "gemini", "pi", "continue",
}


class ContractTests(unittest.TestCase):
    def test_shell_entry_enables_all_supported_providers(self):
        entry = json.loads((ROOT / "config/raven.agents.shell-entry.json").read_text())
        self.assertEqual(entry["id"], "raven.agents")
        self.assertTrue(EXPECTED_PROVIDERS <= set(entry["providers"]))

    def test_manifest_is_user_owned_clone(self):
        manifest = json.loads((ROOT / "omarchy/plugins/raven.agents/manifest.json").read_text())
        self.assertEqual(manifest["id"], "raven.agents")
        self.assertEqual(manifest["omarchy"]["clonedFrom"], "omarchy.agents")
        self.assertTrue(EXPECTED_PROVIDERS <= set(manifest["barWidget"]["defaults"]["providers"]))

    def test_standalone_dashboard_has_local_data_model(self):
        manifest = json.loads(
            (ROOT / "omarchy/plugins/raven.agents-dashboard/manifest.json").read_text()
        )
        dashboard = ROOT / "omarchy/plugins/raven.agents-dashboard"
        self.assertEqual(manifest["id"], "raven.agents-dashboard")
        self.assertEqual(manifest["kinds"], ["panel"])
        self.assertTrue((dashboard / "Panel.qml").is_file())
        self.assertTrue((dashboard / "Main.qml").is_file())
        self.assertTrue((dashboard / "Agent.qml").is_file())

    def test_source_stays_update_safe(self):
        for path in (ROOT / "omarchy").rglob("*"):
            if path.is_file():
                self.assertNotIn("/usr/share/omarchy/", path.read_text(errors="replace"))


if __name__ == "__main__":
    unittest.main()
