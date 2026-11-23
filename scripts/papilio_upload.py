"""Use the managed shared uploader for ESP application-only uploads."""

import runpy
from pathlib import Path

Import("env")

package = env.PioPlatform().get_package_dir("tool-papilio-upload")
if not package:
    raise RuntimeError("Install the declared tool-papilio-upload platform package")
builder = Path(package) / "builder"
configure = runpy.run_path(str(builder / "papilio_upload_hook.py"))["configure_upload"]
configure(env, "esp32", builder)
