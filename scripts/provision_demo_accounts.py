#!/usr/bin/env python3
"""LearnTZ Demo Account & Test Data Provisioning CLI.

Provisions, re-seeds, and audits realistic demo test accounts across
Parents, Learners, and Administrative roles for development and staging
environments.

Usage:
  python3 scripts/provision_demo_accounts.py
  python3 scripts/provision_demo_accounts.py --force-reset
  python3 scripts/provision_demo_accounts.py --overview
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Optional

# Standard local development service role key for Supabase local stack
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


def _call_rpc(endpoint: str, key: str, function_name: str, payload: Optional[Dict[str, Any]] = None, method: str = "POST") -> Any:
    url = f"{endpoint}/rest/v1/rpc/{function_name}"
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    
    data = None
    if method == "POST":
        data = json.dumps(payload or {}).encode("utf-8")

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
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


def provision(force_reset: bool = False, target: str = "local") -> None:
    endpoint, key = _get_config(target)
    print("=" * 70)
    print("LEARNTZ DEMO ACCOUNT PROVISIONING ENGINE")
    print(f"Target Endpoint: {endpoint}")
    print(f"Force Reset:     {force_reset}")
    print("=" * 70)

    try:
        res = _call_rpc(endpoint, key, "provision_demo_data", {"p_force_reset": force_reset}, method="POST")
        print("\nProvisioning Result:")
        print(json.dumps(res, indent=2))
        print("\nDemo Accounts successfully configured!")
        print("Default Parent Password: ParentDemo1234!")
        print("Default Admin Password:  AdminDemo1234!")
        print("Default Learner PIN:     1234")
    except Exception:
        sys.exit(1)


def overview(target: str = "local") -> None:
    endpoint, key = _get_config(target)
    try:
        data = _call_rpc(endpoint, key, "get_demo_accounts_overview", payload=None, method="GET")
        print("=" * 70)
        print("LEARNTZ DEMO ACCOUNTS AUDIT & OVERVIEW")
        print("=" * 70)

        summary = data.get("summary", {})
        print(f"Total Parents:  {summary.get('total_parents', 0)}")
        print(f"Total Learners: {summary.get('total_learners', 0)}")
        print(f"Total Admins:   {summary.get('total_admins', 0)}")
        print("-" * 70)

        print("\n--- DEMO PARENTS ---")
        for p in data.get("parents", []):
            print(f"• [{p.get('country_code')}] {p.get('full_name')} ({p.get('email')}) - Children: {p.get('learner_count')}")

        print("\n--- DEMO LEARNERS ---")
        for l in data.get("learners", []):
            print(f"• [{l.get('country_code')}] {l.get('full_name')} ({l.get('learner_code')}) - Grade: {l.get('grade_name')}, Parent: {l.get('parent_name')}, Mode: {l.get('access_mode')}")

        print("\n--- DEMO ADMINISTRATORS ---")
        for a in data.get("admins", []):
            country = f"[{a.get('country_code')}]" if a.get('country_code') else "[GLOBAL]"
            print(f"• {country} {a.get('full_name')} ({a.get('email')}) - Role: {a.get('role_name')}")

    except Exception:
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="LearnTZ Demo Account & Test Data Provisioning CLI")
    parser.add_argument("--force-reset", action="store_true", help="Reset all demo learner activity and re-provision")
    parser.add_argument("--overview", action="store_true", help="Display overview of all demo accounts and linked learners")
    parser.add_argument("--remote", action="store_true", help="Target remote Supabase staging environment defined in .env")

    args = parser.parse_args()
    target = "remote" if args.remote else "local"

    if args.overview:
        overview(target=target)
    else:
        provision(force_reset=args.force_reset, target=target)


if __name__ == "__main__":
    main()
