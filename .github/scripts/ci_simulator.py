"""Cloud-only XCTest and four-scene visual evidence, with bounded commands."""

import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import time


ROOT = Path("ci-results")
WRAPPER = Path(__file__).with_name("run_with_timeout.py")
BUNDLE_ID = "com.easytech.prototype.WW2Tactics"
REPORT = {"testOutcome": "skipped", "testCount": 0, "testFailures": 0,
          "testSkipped": 0, "screenshots": [], "screenshotOutcome": "failure"}


def run(command, log, seconds=120, capture=False):
    bounded = [sys.executable, str(WRAPPER), str(seconds), *map(str, command)]
    log.write(f"\n$ {shlex.join(bounded)}\n")
    log.flush()
    result = subprocess.run(bounded, stdout=subprocess.PIPE if capture else log,
                            stderr=log, text=True, check=False)
    if capture and result.stdout:
        log.write(result.stdout)
        log.flush()
    return result


def devices():
    payload = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "--json"], text=True, timeout=30)
    choices = {"ipad": [], "iphone": []}
    for runtime, items in json.loads(payload)["devices"].items():
        if ".iOS-" not in runtime:
            continue
        version = tuple(map(int, re.findall(r"\d+", runtime.rsplit(".iOS-", 1)[-1])))
        for item in items:
            name = item.get("name", "")
            category = "ipad" if name.startswith("iPad") else "iphone" if name.startswith("iPhone") else None
            if category and item.get("isAvailable"):
                choices[category].append((version, "Pro" in name, name, item["udid"], runtime))
    return {key: max(value) for key, value in choices.items() if value}


def boot(device, log):
    udid = device[3]
    run(["xcrun", "simctl", "boot", udid], log, seconds=30)
    if run(["xcrun", "simctl", "bootstatus", udid, "-b"], log, seconds=240).returncode:
        raise RuntimeError(f"Simulator boot failed: {device[2]}")
    run(["xcrun", "simctl", "ui", udid, "appearance", "dark"], log, seconds=30)
    run(["xcrun", "simctl", "status_bar", udid, "override", "--time", "09:41", "--batteryState", "charged", "--batteryLevel", "100"], log, seconds=30)


def xctest(device, log):
    REPORT["testOutcome"] = "failure"
    REPORT["testDestination"] = f"platform=iOS Simulator,id={device[3]}"
    command = ["xcodebuild", "-project", "WW2Tactics/WW2Tactics.xcodeproj", "-scheme", "WW2Tactics",
               "-configuration", "Debug", "-destination", REPORT["testDestination"],
               "-derivedDataPath", os.environ["DERIVED_DATA"], "-resultBundlePath", "ci-results/WW2Tactics-tests.xcresult",
               "-parallel-testing-enabled", "NO", "test-without-building", "CODE_SIGNING_ALLOWED=NO"]
    REPORT["testCommand"] = shlex.join(command)
    REPORT["testStartedAt"] = time.time()
    result = run(command, log, seconds=900)
    REPORT["testExitCode"] = result.returncode
    REPORT["testFinishedAt"] = time.time()
    summary = run(["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", "ci-results/WW2Tactics-tests.xcresult"], log, capture=True)
    if summary.returncode == 0:
        data = json.loads(summary.stdout)
        (ROOT / "xctest-summary.json").write_text(json.dumps(data, indent=2) + "\n")
        REPORT["testCount"] = data.get("totalTestCount", 0)
        REPORT["testFailures"] = data.get("failedTests", 0)
        REPORT["testSkipped"] = data.get("skippedTests", 0)
        tree = run(["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", "ci-results/WW2Tactics-tests.xcresult"], log, capture=True)
        if tree.returncode == 0:
            (ROOT / "xctest-test-tree.json").write_text(tree.stdout)
    expected = sum(len(re.findall(r"func test\w+", path.read_text())) for path in Path("WW2Tactics/WW2TacticsTests").glob("*.swift"))
    REPORT["expectedTestCount"] = expected
    if result.returncode == 0 and REPORT["testCount"] >= expected > 0 and REPORT["testFailures"] == 0 and REPORT["testSkipped"] == 0:
        REPORT["testOutcome"] = "success"


def screenshot(category, device, scenario, log):
    path = ROOT / f"battlefield-{category}-{scenario}.png"
    record = {"category": category, "device": device[2], "udid": device[3], "runtime": device[4],
              "orientation": "portrait", "scenario": scenario, "path": str(path), "outcome": "failure"}
    REPORT["screenshots"].append(record)
    arguments = [] if scenario == "default" else ["--ci-selected-combat-impact-steady"]
    result = run(["xcrun", "simctl", "launch", "--terminate-running-process", device[3], BUNDLE_ID, *arguments], log, seconds=90)
    if result.returncode:
        return
    # Retry readability as well as size: an early launch fade can exceed 500 KB.
    for attempt in range(1, 9):
        time.sleep(6)
        result = run(["xcrun", "simctl", "io", device[3], "screenshot", str(path)], log, seconds=30)
        record["captureAttempt"] = attempt
        record["bytes"] = path.stat().st_size if path.exists() else 0
        if result.returncode or record["bytes"] < 500000:
            continue
        inspection = run([str(ROOT / "inspect-screenshot"), str(path)], log, capture=True, seconds=30)
        if inspection.stdout:
            record.update(json.loads(inspection.stdout))
        if inspection.returncode == 0:
            # Wait for a second readable frame, not a single transitional flash.
            if attempt < 2:
                continue
            record["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
            record["outcome"] = "success"
            break
    run(["xcrun", "simctl", "terminate", device[3], BUNDLE_ID], log, seconds=30)


def main():
    selected = {}
    try:
        if os.environ.get("BUILD_STATUS") != "0":
            raise RuntimeError("build-for-testing failed; test/screenshot stages not run")
        with (ROOT / "battlefield-screenshot.log").open("w") as log:
            inspector = run(["xcrun", "swiftc", ".github/scripts/inspect_screenshot.swift", "-o", str(ROOT / "inspect-screenshot")], log, seconds=90)
            inspector_ready = inspector.returncode == 0
            selected = devices()
            if set(selected) != {"ipad", "iphone"}:
                raise RuntimeError("runner must provide existing iPad and iPhone simulators")
            for category in ("ipad", "iphone"):
                device = selected[category]
                boot(device, log)
                if category == "ipad":
                    with (ROOT / "xctest.log").open("w") as test_log:
                        xctest(device, test_log)
                app = Path(os.environ["DERIVED_DATA"]) / "Build/Products/Debug-iphonesimulator/WW2Tactics.app"
                if run(["xcrun", "simctl", "install", device[3], str(app)], log).returncode:
                    raise RuntimeError("app installation failed")
                if inspector_ready:
                    screenshot(category, device, "default", log)
                    screenshot(category, device, "selected-combat-impact-steady", log)
                else:
                    REPORT["error"] = "screenshot inspector did not compile; XCTest still executed independently"
                run(["xcrun", "simctl", "shutdown", device[3]], log, seconds=45)
            if len(REPORT["screenshots"]) == 4 and all(item["outcome"] == "success" for item in REPORT["screenshots"]):
                REPORT["screenshotOutcome"] = "success"
    except Exception as error:
        REPORT["error"] = str(error)
        print(f"Cloud simulator stage failed: {error}", flush=True)
    finally:
        # No runtimes, caches or app binaries are bundled in the result artifact.
        for device in selected.values():
            try:
                subprocess.run(["xcrun", "simctl", "shutdown", device[3]], stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL, timeout=60, check=False)
            except subprocess.TimeoutExpired:
                REPORT["shutdownWarning"] = "Simulator shutdown timed out; runner cleanup required"
        (ROOT / "simulator-report.json").write_text(json.dumps(REPORT, indent=2) + "\n")
        with open(os.environ["GITHUB_ENV"], "a") as env:
            env.write(f"TEST_STATUS={0 if REPORT['testOutcome'] == 'success' else 1}\n")
            env.write(f"SCREENSHOT_STATUS={0 if REPORT['screenshotOutcome'] == 'success' else 1}\n")


if __name__ == "__main__":
    main()
