"""Compatibility wrapper for the legacy W3T importer path used by ItemManager."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
from types import ModuleType


def _load_archive_module() -> ModuleType:
    database_root = pathlib.Path(__file__).resolve().parents[1]
    archive_script = database_root / "_Archive" / "importers" / "wc3_w3t_importer_v2.py"

    if str(database_root) not in sys.path:
        sys.path.insert(0, str(database_root))

    spec = importlib.util.spec_from_file_location(
        "pots_archive_wc3_w3t_importer_v2",
        archive_script,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load importer from {archive_script}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_archive = _load_archive_module()

WC3W3TImporter = _archive.WC3W3TImporter
load_config = getattr(_archive, "load_config", None)
main = _archive.main


if __name__ == "__main__":
    main()
