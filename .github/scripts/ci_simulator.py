"""Cloud-only XCTest and six-scene visual evidence, with bounded commands."""

import hashlib
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import time


ROOT = Path("ci-results")
WRAPPER = Path(__file__).with_name("run_with_timeout.py")
BUNDLE_ID = "com.easytech.prototype.WW2Tactics"
REPORT = {"testOutcome": "skipped", "testCount": 0, "testFailures": 0,
          "testSkipped": 0, "screenshots": [], "screenshotOutcome": "failure",
          "uiTestOutcome": "failure", "visualTests": []}


def run(command, log, seconds=120, capture=False):
    bounded = [sys.executable, str(WRAPPER), str(seconds), *map(str, command)]
    log.write(f"\n$ {shlex.join(bounded)}\n")
    log.flush()
    result = subprocess.run(bounded, stdout=subprocess.PIPE if capture else log,
                            stderr=log, text=True, check=False)
    if capture and result.stdout:
        log.write(result.stdout[:4000])
        if len(result.stdout) > 4000:
            log.write(f"\n[captured {len(result.stdout)} characters; full JSON saved separately]\n")
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
                rank = 3 if name.startswith("iPad Pro") else 2 if name.startswith("iPad Air") else 1
                if category == "iphone":
                    rank = 3 if "Pro Max" in name else 2 if "Pro" in name else 1
                choices[category].append((version, rank, name, item["udid"], runtime))
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
               "-parallel-testing-enabled", "NO", "-only-testing:WW2TacticsTests",
               "test-without-building", "CODE_SIGNING_ALLOWED=NO"]
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
    expected = sum(len(re.findall(r"(?m)^\s*func test\w+\(\)", path.read_text())) for path in Path("WW2Tactics/WW2TacticsTests").glob("*.swift"))
    REPORT["expectedTestCount"] = expected
    if result.returncode == 0 and REPORT["testCount"] >= expected > 0 and REPORT["testFailures"] == 0 and REPORT["testSkipped"] == 0:
        REPORT["testOutcome"] = "success"


def screenshot(category, device, scenario, log):
    orientation = "portrait"
    path = ROOT / f"battlefield-{category}-{scenario}.png"
    record = {"category": category, "device": device[2], "udid": device[3], "runtime": device[4],
              "requestedOrientation": orientation, "scenario": scenario, "path": str(path), "outcome": "failure"}
    REPORT["screenshots"].append(record)
    arguments = [] if scenario == "default" else ["--ci-selected-combat-impact-steady"]
    result = run(["xcrun", "simctl", "launch", "--terminate-running-process", device[3], BUNDLE_ID, *arguments], log, seconds=90)
    if result.returncode:
        return
    # Retry readability as well as size: an early launch fade can exceed 500 KB.
    readable_frames = 0
    for attempt in range(1, 9):
        time.sleep(6)
        result = run(["xcrun", "simctl", "io", device[3], "screenshot", str(path)], log, seconds=30)
        record["captureAttempt"] = attempt
        record["bytes"] = path.stat().st_size if path.exists() else 0
        if result.returncode or record["bytes"] < 500000:
            readable_frames = 0
            continue
        inspection = run([str(ROOT / "inspect-screenshot"), str(path)], log, capture=True, seconds=30)
        if inspection.stdout:
            try:
                record.update(json.loads(inspection.stdout))
            except json.JSONDecodeError:
                record["error"] = "screenshot inspector output was not JSON"
                readable_frames = 0
                continue
        if inspection.returncode == 0 and record.get("orientation") == orientation:
            # Wait for a second readable frame, not a single transitional flash.
            readable_frames += 1
            if readable_frames < 2:
                continue
            record["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
            record["outcome"] = "success"
            break
        else:
            readable_frames = 0
    run(["xcrun", "simctl", "terminate", device[3], BUNDLE_ID], log, seconds=30)


def json_objects(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from json_objects(child)
    elif isinstance(value, list):
        for child in value:
            yield from json_objects(child)


def landscape_evidence(category, device, inspector_ready):
    bundle = ROOT / f"WW2Tactics-{category}-ui.xcresult"
    test = {"category": category, "outcome": "failure", "resultBundlePath": str(bundle)}
    REPORT["visualTests"].append(test)
    path = ROOT / f"battlefield-{category}-selected-combat-impact-steady-landscape.png"
    image = {"category": category, "device": device[2], "udid": device[3], "runtime": device[4],
             "requestedOrientation": "landscape", "scenario": "selected-combat-impact-steady",
             "source": "XCUITest original attachment", "path": str(path), "outcome": "failure"}
    REPORT["screenshots"].append(image)
    with (ROOT / "landscape-ui-tests.log").open("a") as log:
        command = ["xcodebuild", "-project", "WW2Tactics/WW2Tactics.xcodeproj", "-scheme", "WW2Tactics",
                   "-configuration", "Debug", "-destination", f"platform=iOS Simulator,id={device[3]}",
                   "-derivedDataPath", os.environ["DERIVED_DATA"], "-resultBundlePath", str(bundle),
                   "-parallel-testing-enabled", "NO", "-only-testing:WW2TacticsVisualUITests",
                   "test-without-building", "CODE_SIGNING_ALLOWED=NO"]
        test["command"] = shlex.join(command)
        test["startedAt"] = time.time()
        result = run(command, log, seconds=420)
        test["finishedAt"] = time.time()
        test["exitCode"] = result.returncode
        summary = run(["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(bundle)], log, capture=True)
        if summary.returncode:
            return
        data = json.loads(summary.stdout)
        (ROOT / f"{category}-ui-summary.json").write_text(json.dumps(data, indent=2) + "\n")
        test.update({"testCount": data.get("totalTestCount", 0), "failures": data.get("failedTests", 0),
                     "skipped": data.get("skippedTests", 0)})
        if result.returncode or test["testCount"] != 1 or test["failures"] or test["skipped"]:
            return
        test["outcome"] = "success"
        exports = ROOT / f"{category}-ui-attachments"
        export = run(["xcrun", "xcresulttool", "export", "attachments", "--path", str(bundle),
                      "--output-path", str(exports)], log, seconds=90)
        if export.returncode or not inspector_ready:
            return
        manifest = exports / "manifest.json"
        if not manifest.exists():
            image["error"] = "XCTest attachment manifest is missing"
            return
        attachments = []
        for item in json_objects(json.loads(manifest.read_text())):
            label = item.get("suggestedHumanReadableName", item.get("name", ""))
            filename = item.get("exportedFileName", item.get("fileName", ""))
            if "battlefield-landscape-" in label and filename:
                candidate = (exports / filename).resolve()
                if candidate.is_relative_to(exports.resolve()) and candidate.is_file():
                    attachments.append((label, candidate))
        if len(attachments) != 2:
            image["error"] = f"Expected two explicitly named original attachments, got {len(attachments)}"
            log.write(manifest.read_text()[:12000])
            return
        image["frames"] = []
        for label, original in sorted(attachments):
            inspection = run([str(ROOT / "inspect-screenshot"), str(original)], log, capture=True, seconds=30)
            frame = json.loads(inspection.stdout) if inspection.stdout else {}
            frame.update({"attachmentName": label, "bytes": original.stat().st_size,
                          "sha256": hashlib.sha256(original.read_bytes()).hexdigest()})
            image["frames"].append(frame)
            if inspection.returncode or frame.get("orientation") != "landscape" or frame["bytes"] < 500000:
                image["error"] = "Original landscape frame failed orientation, readability, size or system overlay gate"
                return
            image.update(frame)
        # Preserve the original bytes. No crop, resize, orientation transform or notification retouch.
        shutil.copyfile(sorted(attachments)[-1][1], path)
        image["captureAttempt"] = 2
        image["outcome"] = "success"


def boot_category(item):
    category, device = item
    with (ROOT / f"boot-{category}.log").open("w") as log:
        boot(device, log)


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
            # Migration dominates fresh cloud runners; boot the two existing devices concurrently.
            with ThreadPoolExecutor(max_workers=2) as pool:
                list(pool.map(boot_category, selected.items()))
            for category in ("ipad", "iphone"):
                device = selected[category]
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
                landscape_evidence(category, device, inspector_ready)
                run(["xcrun", "simctl", "shutdown", device[3]], log, seconds=45)
            if len(REPORT["screenshots"]) == 6 and all(item["outcome"] == "success" for item in REPORT["screenshots"]):
                REPORT["screenshotOutcome"] = "success"
            if len(REPORT["visualTests"]) == 2 and all(item["outcome"] == "success" for item in REPORT["visualTests"]):
                REPORT["uiTestOutcome"] = "success"
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
            env.write(f"UI_TEST_STATUS={0 if REPORT['uiTestOutcome'] == 'success' else 1}\n")


if __name__ == "__main__":
    main()
