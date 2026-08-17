"""Unit tests for Broadlink dispatch + code store (offline)."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "lib"))

from broadlink_codes import list_codes, save_code, validate_code_record  # noqa: E402
from broadlink_core import RM_MAX_TYPE  # noqa: E402
from broadlink_dispatch_parse import is_broadlink_command, parse_dispatch  # noqa: E402


def test_rm_max_type():
    assert RM_MAX_TYPE == 0xAF8B


def test_parse_status():
    assert parse_dispatch("@openclaw broadlink status", "openclaw")["action"] == "status"


def test_parse_send_strips_confirm():
    out = parse_dispatch("@openclaw broadlink send tv_power confirm", "openclaw")
    assert out["action"] == "send"
    assert out["args"] == ["tv_power"]


def test_is_broadlink_command():
    assert is_broadlink_command("@openclaw broadlink list", "openclaw")
    assert not is_broadlink_command("@alfred subaru status", "openclaw")


def test_code_roundtrip(tmp_path):
    assert validate_code_record({"name": "bad name", "media": "ir", "payload": "x"})
    save_code(
        {"name": "amp_vol_up", "media": "ir", "payload": "QQ==", "safety_class": "low"},
        root=tmp_path,
    )
    assert len(list_codes(root=tmp_path)) == 1
