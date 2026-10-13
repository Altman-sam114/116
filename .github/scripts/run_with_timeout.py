"""Run one CI command with a portable timeout and isolated process group."""

import argparse
import math
import os
from pathlib import Path
import shlex
import signal
import subprocess
import sys
import tempfile
import time


def stop_group(process):
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        pass
    # The leader may already have exited while a descendant ignores TERM.
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.wait()


def run(seconds, command):
    label = shlex.join(command)
    print(f"[bounded] limit={seconds:g}s command={label}", file=sys.stderr, flush=True)
    try:
        process = subprocess.Popen(command, start_new_session=True)
    except FileNotFoundError as error:
        print(f"[bounded] command not found: {error}; exit=127", file=sys.stderr)
        return 127
    except OSError as error:
        print(f"[bounded] command could not start: {error}; exit=126", file=sys.stderr)
        return 126

    def cancel(signum, _frame):
        print(f"[bounded] interrupted by signal {signum}: {label}", file=sys.stderr, flush=True)
        raise SystemExit(128 + signum)

    previous_handlers = {
        signum: signal.signal(signum, cancel)
        for signum in (signal.SIGINT, signal.SIGTERM)
    }
    try:
        try:
            status = process.wait(timeout=seconds)
        except subprocess.TimeoutExpired:
            print(f"[bounded] timeout after {seconds:g}s: {label}; exit=124", file=sys.stderr, flush=True)
            stop_group(process)
            return 124
        except BaseException:
            stop_group(process)
            raise
        shell_status = status if status >= 0 else 128 - status
        print(f"[bounded] command exit={shell_status}: {label}", file=sys.stderr, flush=True)
        return shell_status
    finally:
        for signum, handler in previous_handlers.items():
            signal.signal(signum, handler)


def self_test():
    wrapper = str(Path(__file__).resolve())

    def check(name, seconds, command, expected):
        result = subprocess.run(
            [sys.executable, wrapper, str(seconds), *command],
            timeout=12,
            check=False,
        )
        print(f"contract {name}: expected={expected} actual={result.returncode}", flush=True)
        if result.returncode != expected:
            raise RuntimeError(f"contract failed: {name}")

    check("success", 3, [sys.executable, "-c", "pass"], 0)
    check("ordinary-failure", 3, [sys.executable, "-c", "raise SystemExit(7)"], 7)
    check("timeout", 0.15, [sys.executable, "-c", "import time; time.sleep(5)"], 124)
    check("missing-command", 3, ["/ww2tactics-no-such-command"], 127)
    check("signal-exit", 3, [sys.executable, "-c", "import os, signal; os.kill(os.getpid(), signal.SIGTERM)"], 143)

    with tempfile.TemporaryDirectory(prefix="ww2tactics-timeout-") as directory:
        marker = Path(directory) / "descendant-survived"
        ready = Path(directory) / "descendant-ready"
        child = (
            "import signal, time; from pathlib import Path; "
            "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
            f"Path({str(ready)!r}).write_text('ready'); "
            f"time.sleep(1.5); Path({str(marker)!r}).write_text('unexpected')"
        )
        leader = (
            "import subprocess, sys, time; "
            f"subprocess.Popen([sys.executable, '-c', {child!r}]); "
            "time.sleep(10)"
        )
        check("descendant-cleanup", 0.8, [sys.executable, "-c", leader], 124)
        time.sleep(1.6)
        if not ready.exists() or marker.exists():
            raise RuntimeError("descendant cleanup contract failed")
        print("contract descendant-cleanup: TERM-ignoring child terminated with process group", flush=True)
    print("Timeout wrapper contracts passed", flush=True)
    return 0


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("seconds", type=float)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    arguments = parser.parse_args()
    if not math.isfinite(arguments.seconds) or arguments.seconds <= 0:
        parser.error("seconds must be positive and finite")
    if not arguments.command:
        parser.error("a command is required")
    return run(arguments.seconds, arguments.command)


if __name__ == "__main__":
    sys.exit(main())
