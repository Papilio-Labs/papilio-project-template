import unittest
from pathlib import Path

from platformio.package.meta import PackageSpec
from platformio.project.config import ProjectConfig


class UploadConfigTests(unittest.TestCase):
    def test_shared_uploader_git_dependency_parses_as_named_package(self):
        config = ProjectConfig(str(Path(__file__).resolve().parents[1] / "platformio.ini"))
        specs = [
            PackageSpec(value)
            for value in config.get("env:esp32", "platform_packages")
        ]
        uploader = next(spec for spec in specs if spec.name == "tool-papilio-upload")
        self.assertEqual(
            uploader.uri, "git+https://github.com/Papilio-Labs/platform-gowin.git"
        )


if __name__ == "__main__":
    unittest.main()
