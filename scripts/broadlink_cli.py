#!/usr/bin/env python3
"""CLI for Broadlink discover/auth/status/learn/send/list."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

LIB = Path(__file__).resolve().parent / "lib"
sys.path.insert(0, str(LIB))

from broadlink_codes import list_codes, load_code, save_code  # noqa: E402
from broadlink_core import (  # noqa: E402
    b64_decode,
    b64_encode,
    connect_device,
    device_status_dict,
    env_bool,
    hello_device,
    learn_ir,
    resolve_device,
    send_packet,
)


def emit(payload: dict) -> int:
    print(json.dumps(payload))
    return 0 if payload.get("ok") else 1


def cmd_status(args: argparse.Namespace) -> int:
    dcfg = resolve_device(args.device)
    return emit(device_status_dict(dcfg, try_auth=not args.no_auth))


def cmd_discover(args: argparse.Namespace) -> int:
    dcfg = resolve_device(args.device)
    try:
        device = hello_device(dcfg["host"])
        return emit(
            {
                "ok": True,
                "command": "discover",
                "host": dcfg["host"],
                "devtype": hex(int(device.devtype)),
                "class": getattr(device, "TYPE", type(device).__name__),
                "name": getattr(device, "name", None),
                "mac": ":".join(f"{b:02x}" for b in device.mac),
                "cloud": getattr(device, "cloud", None),
            }
        )
    except Exception as exc:  # noqa: BLE001
        return emit({"ok": False, "command": "discover", "error_code": "hello_failed", "errors": [str(exc)]})


def cmd_auth(args: argparse.Namespace) -> int:
    dcfg = resolve_device(args.device)
    try:
        device = connect_device(dcfg, auth=True)
        return emit(
            {
                "ok": True,
                "command": "auth",
                "class": getattr(device, "TYPE", None),
                "devtype": hex(int(device.devtype)),
                "name": getattr(device, "name", None),
            }
        )
    except Exception as exc:  # noqa: BLE001
        return emit(
            {
                "ok": False,
                "command": "auth",
                "error_code": "auth_failed",
                "errors": [str(exc)],
                "hint": "Unlock in Magic Home (Lock off / 3rd-party) — see docs/UNLOCK-SOP.md",
            }
        )


def cmd_list(_args: argparse.Namespace) -> int:
    codes = list_codes()
    return emit(
        {
            "ok": True,
            "command": "list",
            "count": len(codes),
            "codes": [
                {
                    "name": c.get("name"),
                    "media": c.get("media"),
                    "safety_class": c.get("safety_class"),
                    "device": c.get("device"),
                    "aliases": c.get("aliases") or [],
                }
                for c in codes
            ],
        }
    )


def cmd_learn(args: argparse.Namespace) -> int:
    if not env_bool("BROADLINK_ENABLED") and not args.force:
        return emit(
            {
                "ok": False,
                "command": "learn",
                "error_code": "disabled",
                "errors": ["Set BROADLINK_ENABLED=1 to learn codes"],
            }
        )
    if args.media == "rf" and not env_bool("BROADLINK_RF_ENABLED"):
        return emit(
            {
                "ok": False,
                "command": "learn",
                "error_code": "rf_disabled",
                "errors": ["Set BROADLINK_RF_ENABLED=1 for RF learn"],
            }
        )
    if args.dry_run:
        return emit(
            {
                "ok": True,
                "command": "learn",
                "dry_run": True,
                "name": args.name,
                "media": args.media,
                "would": "enter_learning + save base64",
            }
        )
    dcfg = resolve_device(args.device)
    try:
        device = connect_device(dcfg, auth=True)
        if args.media == "rf":
            return emit(
                {
                    "ok": False,
                    "command": "learn",
                    "error_code": "rf_learn_manual",
                    "errors": [
                        "RF learn requires frequency sweep; use broadlink_cli or extend CLI in a later cut"
                    ],
                }
            )
        packet = learn_ir(device, timeout_s=float(args.timeout))
        rec = {
            "name": args.name,
            "media": "ir",
            "encoding": "broadlink_base64",
            "payload": b64_encode(packet),
            "device": dcfg.get("id") or "rm-max",
            "safety_class": args.safety_class,
            "notes": args.notes or "",
        }
        path = save_code(rec)
        return emit({"ok": True, "command": "learn", "name": args.name, "path": str(path), "bytes": len(packet)})
    except TimeoutError:
        return emit({"ok": False, "command": "learn", "error_code": "learn_timeout", "errors": ["No IR packet within timeout"]})
    except Exception as exc:  # noqa: BLE001
        return emit({"ok": False, "command": "learn", "error_code": "learn_failed", "errors": [str(exc)]})


def cmd_send(args: argparse.Namespace) -> int:
    if env_bool("BROADLINK_DRY_RUN") or args.dry_run:
        return emit(
            {
                "ok": True,
                "command": "send",
                "dry_run": True,
                "name": args.name,
                "would_send": True,
            }
        )
    if not env_bool("BROADLINK_ENABLED"):
        return emit(
            {
                "ok": False,
                "command": "send",
                "error_code": "disabled",
                "errors": ["Set BROADLINK_ENABLED=1"],
            }
        )
    if not env_bool("BROADLINK_ACTUATION_ENABLED") and not args.force:
        return emit(
            {
                "ok": False,
                "command": "send",
                "error_code": "actuation_disabled",
                "errors": ["Set BROADLINK_ACTUATION_ENABLED=1 after unlock + learn proof"],
            }
        )
    try:
        rec = load_code(args.name)
    except FileNotFoundError as exc:
        return emit({"ok": False, "command": "send", "error_code": "unknown_code", "errors": [str(exc)]})
    if rec.get("media") == "rf" and not env_bool("BROADLINK_RF_ENABLED"):
        return emit(
            {
                "ok": False,
                "command": "send",
                "error_code": "rf_disabled",
                "errors": ["RF send blocked (BROADLINK_RF_ENABLED=0)"],
            }
        )
    dcfg = resolve_device(args.device or rec.get("device"))
    try:
        device = connect_device(dcfg, auth=True)
        send_packet(device, b64_decode(rec["payload"]))
        return emit(
            {
                "ok": True,
                "command": "send",
                "name": rec.get("name"),
                "media": rec.get("media"),
                "safety_class": rec.get("safety_class"),
            }
        )
    except Exception as exc:  # noqa: BLE001
        return emit({"ok": False, "command": "send", "error_code": "send_failed", "errors": [str(exc)]})


def cmd_help(_args: argparse.Namespace) -> int:
    return emit(
        {
            "ok": True,
            "command": "help",
            "usage": [
                "broadlink-device.sh status|discover|auth|list",
                "broadlink-device.sh learn --name <slug> [--safety-class low|high]",
                "broadlink-device.sh send <name>   # needs BROADLINK_ACTUATION_ENABLED=1",
                "Talk: @openclaw broadlink status|list|send <name> confirm|help",
            ],
        }
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="broadlink_cli")
    parser.add_argument("--device", default=None)
    parser.add_argument("--dry-run", action="store_true")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_status = sub.add_parser("status")
    p_status.add_argument("--no-auth", action="store_true")
    p_status.set_defaults(func=cmd_status)

    p_disc = sub.add_parser("discover")
    p_disc.set_defaults(func=cmd_discover)

    p_auth = sub.add_parser("auth")
    p_auth.set_defaults(func=cmd_auth)

    p_list = sub.add_parser("list")
    p_list.set_defaults(func=cmd_list)

    p_learn = sub.add_parser("learn")
    p_learn.add_argument("--name", required=True)
    p_learn.add_argument("--media", choices=["ir", "rf"], default="ir")
    p_learn.add_argument("--safety-class", choices=["low", "high"], default="low")
    p_learn.add_argument("--notes", default="")
    p_learn.add_argument("--timeout", default="30")
    p_learn.add_argument("--force", action="store_true")
    p_learn.set_defaults(func=cmd_learn)

    p_send = sub.add_parser("send")
    p_send.add_argument("name")
    p_send.add_argument("--force", action="store_true")
    p_send.set_defaults(func=cmd_send)

    p_help = sub.add_parser("help")
    p_help.set_defaults(func=cmd_help)

    args = parser.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    sys.exit(main())
