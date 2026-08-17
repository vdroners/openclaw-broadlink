"""Broadlink local control helpers with RM Max (0xAF8B) rmpro framing overlay.

Upstream python-broadlink does not ship RM Max in a released PyPI cut. PR #838
and issue #829 track support. Wrong framing (rm4pro <HI) produces false
"device locked" errors; RM Max needs rmpro-style <I framing.
"""

from __future__ import annotations

import base64
import json
import os
import socket
import time
from pathlib import Path
from typing import Any

RM_MAX_TYPE = 0xAF8B


def env_bool(name: str, default: str = "0") -> bool:
    return os.environ.get(name, default).strip() == "1"


def openclaw_dir() -> Path:
    return Path(os.environ.get("OPENCLAW_DIR", Path.home() / ".openclaw"))


def devices_json_path() -> Path:
    return Path(
        os.environ.get(
            "BROADLINK_DEVICES_JSON",
            str(openclaw_dir() / "config" / "broadlink-devices.json"),
        )
    )


def codes_dir() -> Path:
    return Path(
        os.environ.get(
            "BROADLINK_CODES_DIR",
            str(openclaw_dir() / "state" / "broadlink-codes"),
        )
    )


def load_devices_config() -> dict[str, Any]:
    path = devices_json_path()
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    host = os.environ.get("BROADLINK_HOST", "10.0.0.174")
    mac = os.environ.get("BROADLINK_MAC", "34:8e:89:b1:10:2a")
    typ = os.environ.get("BROADLINK_TYPE", "0xaf8b")
    nick = os.environ.get("BROADLINK_NICKNAME", "rm-max")
    return {
        "schema_version": 1,
        "default_device": nick,
        "devices": [
            {
                "id": nick,
                "nickname": nick,
                "aliases": ["broadlink", "rmmax"],
                "host": host,
                "mac": mac,
                "type": typ,
                "model": "RM Max",
                "capabilities": ["ir", "rf"],
            }
        ],
    }


def resolve_device(name: str | None = None) -> dict[str, Any]:
    cfg = load_devices_config()
    target = (name or cfg.get("default_device") or "").strip().lower()
    devices = cfg.get("devices") or []
    if not devices:
        raise RuntimeError("no_devices_configured")
    for d in devices:
        aliases = {str(d.get("id", "")).lower(), str(d.get("nickname", "")).lower()}
        aliases |= {a.lower() for a in (d.get("aliases") or [])}
        if target and target in aliases:
            return d
    if name:
        raise RuntimeError(f"unknown_device:{target}")
    for d in devices:
        if d.get("id") == cfg.get("default_device"):
            return d
    return devices[0]


def apply_rm_max_patch() -> None:
    """Ensure 0xAF8B is registered on rmpro in SUPPORTED_TYPES when present."""
    import broadlink
    from broadlink.remote import rmpro

    supported = getattr(broadlink, "SUPPORTED_TYPES", None)
    if not isinstance(supported, dict):
        return
    # Strip from other class maps
    for mapping in supported.values():
        if isinstance(mapping, dict):
            mapping.pop(RM_MAX_TYPE, None)
    for cls, mapping in supported.items():
        if not isinstance(mapping, dict):
            continue
        if cls is rmpro or getattr(cls, "TYPE", None) == "RMPRO" or getattr(cls, "__name__", "") == "rmpro":
            mapping[RM_MAX_TYPE] = ("RM Max", "Broadlink")
            return
    supported[rmpro] = {RM_MAX_TYPE: ("RM Max", "Broadlink")}


def _unicast_hello_raw(host: str, port: int = 80, timeout: float = 5.0) -> tuple[bytes, tuple]:
    packet = bytearray(0x30)
    packet[0x26] = 6
    checksum = sum(packet) & 0xFFFF
    packet[0x20:0x22] = checksum.to_bytes(2, "little")
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(timeout)
    sock.bind(("", 0))
    try:
        sock.sendto(packet, (host, port))
        return sock.recvfrom(1024)
    finally:
        sock.close()


def hello_device(host: str, port: int = 80, timeout: float = 5.0):
    """Return an authenticated-ready device instance (rmpro for RM Max)."""
    apply_rm_max_patch()
    import broadlink
    from broadlink.remote import rmpro

    try:
        device = broadlink.hello(host, port=port, timeout=timeout)
    except Exception:
        data, addr = _unicast_hello_raw(host, port=port, timeout=timeout)
        if len(data) < 0x40:
            raise RuntimeError("hello_short_reply") from None
        devtype = int.from_bytes(data[0x34:0x36], "little")
        mac = data[0x3a:0x40]
        name = data[0x40:].split(b"\x00")[0].decode("utf-8", "ignore") or "RM Max"
        cloud = bool(data[0x2c]) if len(data) > 0x2c else False
        if devtype == RM_MAX_TYPE:
            return rmpro((addr[0], addr[1]), mac, devtype, name=name, cloud=cloud)
        return broadlink.gendevice(devtype, (addr[0], addr[1]), mac, name=name, cloud=cloud)

    if int(getattr(device, "devtype", 0)) == RM_MAX_TYPE and getattr(device, "TYPE", "") != "RMPRO":
        return rmpro(
            (host, port),
            device.mac,
            RM_MAX_TYPE,
            name=getattr(device, "name", "RM Max"),
            cloud=getattr(device, "cloud", False),
        )
    return device


def connect_device(device_cfg: dict[str, Any] | None = None, *, auth: bool = True):
    dcfg = device_cfg or resolve_device()
    device = hello_device(dcfg["host"])
    if auth:
        device.auth()
    return device


def device_status_dict(device_cfg: dict[str, Any] | None = None, *, try_auth: bool = True) -> dict[str, Any]:
    dcfg = device_cfg or resolve_device()
    out: dict[str, Any] = {
        "ok": True,
        "command": "status",
        "device": {
            "id": dcfg.get("id"),
            "host": dcfg.get("host"),
            "mac": dcfg.get("mac"),
            "type": dcfg.get("type"),
            "model": dcfg.get("model"),
            "discovery_name": dcfg.get("discovery_name"),
        },
        "hello": False,
        "auth": False,
        "class": None,
        "devtype": None,
        "name": None,
        "cloud": None,
        "error_code": None,
        "errors": [],
    }
    try:
        device = hello_device(dcfg["host"])
        out["hello"] = True
        out["devtype"] = hex(int(getattr(device, "devtype", 0)))
        out["class"] = getattr(device, "TYPE", type(device).__name__)
        out["name"] = getattr(device, "name", None)
        out["cloud"] = getattr(device, "cloud", None)
        if try_auth:
            try:
                device.auth()
                out["auth"] = True
            except Exception as exc:  # noqa: BLE001
                out["auth"] = False
                out["ok"] = False
                out["error_code"] = "auth_failed"
                out["errors"].append(str(exc))
    except Exception as exc:  # noqa: BLE001
        out["ok"] = False
        out["error_code"] = "hello_failed"
        out["errors"].append(str(exc))
    return out


def learn_ir(device, timeout_s: float = 30.0) -> bytes:
    device.enter_learning()
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        packet = device.check_data()
        if packet:
            return packet
        time.sleep(0.5)
    raise TimeoutError("learn_timeout")


def send_packet(device, packet: bytes) -> None:
    device.send_data(packet)


def b64_encode(packet: bytes) -> str:
    return base64.b64encode(packet).decode("ascii")


def b64_decode(payload: str) -> bytes:
    return base64.b64decode(payload.encode("ascii"))
