"""Compatibility import for the project's installed shared review hook."""

from pathlib import Path
import importlib.util


def open_review_box(body):
    for candidate in (Path.cwd() / ".agents" / "hooks" / "review_boxes.py",
                      Path(__file__).parents[2] / "setup-ai-build-kit" / "templates" /
                      "foundation" / "review_boxes.py"):
        if candidate.is_file():
            spec = importlib.util.spec_from_file_location("shared_review_boxes", candidate)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            return module.open_review_box(body)
    raise ImportError("shared review-box reader is missing")
