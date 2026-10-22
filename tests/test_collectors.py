import importlib.machinery
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "omarchy/bin/omarchy-extra-agent-usage"
LOADER = importlib.machinery.SourceFileLoader("extra_agent_usage", str(SOURCE))
SPEC = importlib.util.spec_from_loader("extra_agent_usage", LOADER)
COLLECTOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(COLLECTOR)


class CollectorTests(unittest.TestCase):
    def test_gemini_fixture_produces_record_contract(self):
        fixture = ROOT / "tests/fixtures/gemini-logs.json"
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "usage"
            COLLECTOR.OUT = output
            COLLECTOR.collect_event_files(
                "gemini",
                "Gemini CLI",
                [fixture.parent],
                ["gemini-logs.json"],
            )
            record = json.loads((output / "gemini.json").read_text())

        self.assertEqual(record["schemaVersion"], 1)
        self.assertEqual(record["id"], "gemini")
        self.assertEqual(record["name"], "Gemini CLI")
        self.assertEqual(record["totalPrompts"], 1)
        self.assertEqual(record["totalSessions"], 1)
        self.assertEqual(record["todayTotalTokens"], 200)
        self.assertEqual(record["limits"], [])

    def test_missing_provider_data_is_a_noop(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "usage"
            COLLECTOR.OUT = output
            COLLECTOR.collect_event_files(
                "continue",
                "Continue",
                [Path(directory) / "missing"],
                ["*.jsonl"],
            )
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
