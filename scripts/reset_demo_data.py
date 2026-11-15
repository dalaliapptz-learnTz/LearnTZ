#!/usr/bin/env python3
"""LearnTZ Demo Learner Data Reset CLI.

Resets sample progress, recommendations, assessments, topic mastery, and active sessions
for demo learner accounts without deleting the account profiles.

Usage:
  python3 scripts/reset_demo_data.py --confirm
  python3 scripts/reset_demo_data.py --confirm --remote
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from typing import Any, Dict

DEFAULT_LOCAL_SERVICE_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0."
    "EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
)


def _load_env_file() -> None:
    env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env")
    if os.path.exists(env_path):
        try:
            with open(env_path, encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, v = line.split("=", 1)
                        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
        except Exception:
            pass


_load_env_file()


def _get_config(target_env: str = "local") -> tuple[str, str]:
    if target_env == "local":
        return "http://127.0.0.1:54321", DEFAULT_LOCAL_SERVICE_KEY
    supabase_url = os.environ.get("SUPABASE_URL", "http://127.0.0.1:54321")
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", DEFAULT_LOCAL_SERVICE_KEY)
    return supabase_url.rstrip("/"), service_key


def _call_rpc(endpoint: str, key: str, function_name: str, payload: Dict[str, Any]) -> Any:
    url = f"{endpoint}/rest/v1/rpc/{function_name}"
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode("utf-8")
            if not raw:
                return None
            return json.loads(raw)
    except urllib.error.HTTPError as err:
        error_body = err.read().decode("utf-8")
        print(f"HTTP Error {err.code} calling {function_name}: {error_body}", file=sys.stderr)
        raise
    except Exception as err:
        print(f"Network error calling {function_name}: {err}", file=sys.stderr)
        raise


def reset(target: str = "local") -> None:
    endpoint, key = _get_config(target)
    print("=" * 70)
    print("LEARNTZ DEMO LEARNER ACTIVITY RESET")
    print(f"Target Endpoint: {endpoint}")
    print("=" * 70)

    try:
        res = _call_rpc(endpoint, key, "reset_demo_data", {})
        print("\nReset Result:")
        print(json.dumps(res, indent=2))
        print("\nDemo learner progress and recommendations reset successfully.")
    except Exception:
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="LearnTZ Demo Learner Data Reset CLI")
    parser.add_argument("--confirm", action="store_true", required=True, help="Explicit confirmation to reset demo activity data")
    parser.add_argument("--remote", action="store_true", help="Target remote Supabase staging environment defined in .env")

    args = parser.parse_args()
    target = "remote" if args.remote else "local"

    if not args.confirm:
        print("Aborted: --confirm flag is required to reset demo activity data.", file=sys.stderr)
        sys.exit(1)

    reset(target=target)


if __name__ == "__main__":
    main()
