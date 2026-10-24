"""Package stage outcomes separately from actual XCTest counts."""

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import xml.etree.ElementTree as ET


root = Path("ci-results")
report_path = root / "simulator-report.json"
simulator = json.loads(report_path.read_text()) if report_path.exists() else {
    "testOutcome": "skipped", "testCount": 0, "screenshots": [], "screenshotOutcome": "failure"
}
stages = [
    ("static-checks", "STATIC_STATUS", "static-checks.log"),
    ("rules-smoke", "SMOKE_STATUS", "rules-smoke.log"),
    ("xcode-build-for-testing", "BUILD_STATUS", "xcodebuild.log"),
    ("xctest-execution", "TEST_STATUS", "xctest.log"),
    ("six-battlefield-screenshots", "SCREENSHOT_STATUS", "battlefield-screenshot.log"),
]
outcomes = {name: "success" if os.environ.get(key, "1") == "0" else "failure" for name, key, _ in stages}
artwork = [{"path": str(path), "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
           for path in sorted(Path("WW2Tactics/WW2Tactics/BattlefieldArt").glob("*.png"))]
(root / "artwork-resources.json").write_text(json.dumps(artwork, indent=2) + "\n")
manifest = {
    "version": os.environ["CI_VERSION"], "branch": os.environ["GITHUB_REF_NAME"],
    "commitSha": os.environ["GITHUB_SHA"], "shortSha": os.environ["SHORT_SHA"],
    "runId": os.environ["GITHUB_RUN_ID"], "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"],
    "workflowName": "WW2Tactics CI Results", "createdAt": datetime.now(timezone.utc).isoformat(),
    "projectName": "WW2Tactics", "scheme": "WW2Tactics",
    "destination": "generic/platform=iOS Simulator", "resultBundlePath": os.environ["RESULT_BUNDLE"],
    "testResultBundlePath": "ci-results/WW2Tactics-tests.xcresult",
    "resultBundleExists": Path(os.environ["RESULT_BUNDLE"]).is_dir(),
    "testResultBundleExists": (root / "WW2Tactics-tests.xcresult").is_dir(),
    "junitPath": "ci-results/junit.xml", "buildLogPath": "ci-results/xcodebuild.log",
    "failureSummaryPath": "ci-results/ci-failure-summary.md",
    "staticChecksOutcome": outcomes["static-checks"], "smokeTestOutcome": outcomes["rules-smoke"],
    "buildOutcome": outcomes["xcode-build-for-testing"],
    "artworkResources": artwork,
    **simulator,
}
(root / "ci-artifact-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
lines = ["# WW2Tactics CI Results", "", *[f"- {key}: {manifest[key]}" for key in
         ("version", "branch", "commitSha", "runId", "runAttempt")], ""]
for name, _, log in stages:
    lines.append(f"- {name}: {outcomes[name]} (ci-results/{log})")
lines.extend(["", f"Actual XCTest: {simulator.get('testCount', 0)} total, "
              f"{simulator.get('testFailures', 0)} failed, {simulator.get('testSkipped', 0)} skipped.",
              "Stage counts are not XCTest counts. Screenshots do not prove touch/VoiceOver behavior."])
if simulator.get("error"):
    lines.extend(["", f"Simulator error: {simulator['error']}"])
for image in simulator.get("screenshots", []):
    lines.append(f"- {image['path']}: {image['outcome']}, {image.get('width')}x{image.get('height')}, "
                 f"{image.get('bytes', 0)} bytes, luminance {image.get('meanLuminance')}")
(root / "ci-failure-summary.md").write_text("\n".join(lines) + "\n")
suites = ET.Element("testsuites")
suite = ET.SubElement(suites, "testsuite", name="CI stages (not XCTest cases)", tests=str(len(stages)),
                      failures=str(sum(value != "success" for value in outcomes.values())), errors="0", skipped="0")
for name, _, log in stages:
    case = ET.SubElement(suite, "testcase", classname="WW2TacticsCI", name=name)
    if outcomes[name] != "success":
        ET.SubElement(case, "failure", message=f"See {log}")
tree_path = root / "xctest-test-tree.json"
if tree_path.exists():
    cases = []

    def collect(value):
        if isinstance(value, dict):
            if value.get("nodeType") == "Test Case":
                cases.append(value)
            else:
                for child in value.values():
                    collect(child)
        elif isinstance(value, list):
            for child in value:
                collect(child)

    collect(json.loads(tree_path.read_text()))
    actual = ET.SubElement(suites, "testsuite", name="Actual XCTest cases", tests=str(len(cases)),
                           failures=str(simulator.get("testFailures", 0)), errors="0", skipped=str(simulator.get("testSkipped", 0)))
    for item in cases:
        case = ET.SubElement(actual, "testcase", classname="WW2TacticsTests", name=item.get("nodeIdentifier", item.get("name", "unknown")))
        if item.get("result") in ("Failed", "Failure"):
            ET.SubElement(case, "failure", message="See XCTest result bundle")
        elif item.get("result") == "Skipped":
            ET.SubElement(case, "skipped")
ET.indent(suites, space="  ")
ET.ElementTree(suites).write(root / "junit.xml", encoding="utf-8", xml_declaration=True)
