import hashlib
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools import curseforge as cf


class ReleaseTests(unittest.TestCase):
    def test_notes_and_game_version_are_specific_to_this_release(self):
        log = "## v1.0.10 · today\n\n- New\n\n## v1.0.1 · earlier\n\n- Old\n"
        notes = cf.release_notes(log, "v1.0.1")
        versions = [{"name": "1.60.1", "id": 42}, {"name": "1.60.0", "id": 41}]
        self.assertEqual(cf.metadata("v1.0.1", versions, notes), {
            "displayName": "Forever Pet Modes v1.0.1", "changelog": "- Old",
            "releaseType": "release", "changelogType": "markdown", "gameVersions": [42]})
        with self.assertRaises(ValueError):
            cf.release_notes(log, "v1.0.2")
        for versions in ([], versions + [versions[0]]):
            with self.assertRaises(ValueError):
                cf.metadata("v1.0.1", versions, notes)

    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.archive = Path(tmp.name) / "ForeverPetModes-v1.2.3.zip"
        self.archive.write_bytes(b"tested zip")
        self.asset = {"id": 3, "name": self.archive.name, "label": "",
                      "digest": "sha256:" + hashlib.sha256(b"tested zip").hexdigest()}
        self.labels = []

        def github(path, *args):
            if args:
                self.asset["label"] = args[-1].removeprefix("label=")
                self.labels.append(self.asset["label"])
                return self.asset
            return {"assets": [self.asset]}

        for patcher in (patch.dict(cf.os.environ, GITHUB_REPOSITORY="owner/repo"),
                        patch.object(cf, "github", github)):
            patcher.start()
            self.addCleanup(patcher.stop)

    @patch.object(cf, "curseforge", return_value={"id": 175})
    def test_rerun_uses_existing_receipt(self, submit):
        cf.publish("v1.2.3", self.archive, {})
        cf.publish("v1.2.3", self.archive, {})
        self.assertEqual(self.labels, [f"{self.archive.name} ({cf.PENDING})",
                                       f"{self.archive.name} (CurseForge file 175)"])
        submit.assert_called_once_with("projects/1826325/upload-file", "--form-string",
                                       "metadata={}", "--form", f"file=@{self.archive}")

    @patch.object(cf, "curseforge", side_effect=TimeoutError)
    def test_uncertain_upload_is_not_repeated(self, submit):
        with self.assertRaises(TimeoutError):
            cf.publish("v1.2.3", self.archive, {})
        with self.assertRaisesRegex(ValueError, "pending"):
            cf.publish("v1.2.3", self.archive, {})
        self.assertEqual(submit.call_count, 1)

    @patch.object(cf, "curseforge")
    def test_checksum_mismatch_blocks_upload(self, submit):
        self.archive.write_bytes(b"different zip")
        with self.assertRaisesRegex(ValueError, "differs"):
            cf.publish("v1.2.3", self.archive, {})
        self.assertFalse(self.labels)
        submit.assert_not_called()
