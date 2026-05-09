#!/usr/bin/env python3
"""Generate MoonBit tests from nst/JSONTestSuite test_parsing files."""

from __future__ import annotations

import argparse
import base64
import hashlib
import subprocess
from dataclasses import dataclass
from pathlib import Path


UPSTREAM_REPO = "https://github.com/nst/JSONTestSuite"
UPSTREAM_COMMIT = "1ef36fa01286573e846ac449e8683f8833c5b26a"
DEFAULT_UPSTREAM = Path("/tmp/json-testsuite-1ef36fa")
TEST_DIR = Path("src/tests")
MAX_LITERAL_CHUNK = 96


@dataclass(frozen=True)
class Case:
    filename: str
    category: str
    raw: bytes
    support: str
    reason: str
    text: str | None

    @property
    def name(self) -> str:
        return self.filename.removesuffix(".json")

    @property
    def source_url(self) -> str:
        return (
            f"{UPSTREAM_REPO}/blob/{UPSTREAM_COMMIT}/test_parsing/{self.filename}"
        )

    @property
    def policy(self) -> str:
        return {
            "y": "Accept",
            "n": "Reject",
            "i": "AcceptOrReject",
        }[self.category]


def main() -> None:
    args = parse_args()
    upstream = args.upstream
    verify_upstream_commit(upstream, skip=args.skip_commit_check)
    cases = read_cases(upstream)
    out_dir = args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    write_manifest(out_dir / "json_testsuite_manifest.mbt", cases)
    write_tests(
        out_dir / "json_testsuite_y_test.mbt",
        [case for case in cases if case.category == "y" and case.support == "utf8_text"],
        "expect_accept",
    )
    write_tests(
        out_dir / "json_testsuite_n_test.mbt",
        [case for case in cases if case.category == "n" and case.support == "utf8_text"],
        "expect_reject",
    )
    write_tests(
        out_dir / "json_testsuite_i_test.mbt",
        [case for case in cases if case.category == "i" and case.support == "utf8_text"],
        "expect_accept_or_reject",
    )
    print_summary(cases)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--upstream",
        type=Path,
        default=DEFAULT_UPSTREAM,
        help="Path to a JSONTestSuite checkout at the pinned commit.",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=TEST_DIR,
        help="Directory for generated MoonBit test files.",
    )
    parser.add_argument(
        "--skip-commit-check",
        action="store_true",
        help="Allow generating from a non-git source tree.",
    )
    return parser.parse_args()


def verify_upstream_commit(upstream: Path, *, skip: bool) -> None:
    if skip:
        return
    try:
        actual = subprocess.check_output(
            ["git", "-C", str(upstream), "rev-parse", "HEAD"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        raise SystemExit(
            f"failed to read git commit from {upstream}; pass --skip-commit-check "
            "only for a verified source archive"
        ) from exc
    if actual != UPSTREAM_COMMIT:
        raise SystemExit(
            f"wrong JSONTestSuite commit: expected {UPSTREAM_COMMIT}, got {actual}"
        )


def read_cases(upstream: Path) -> list[Case]:
    parsing_dir = upstream / "test_parsing"
    paths = sorted(parsing_dir.glob("*.json"))
    if not paths:
        raise SystemExit(f"no JSONTestSuite files found in {parsing_dir}")
    cases = [read_case(path) for path in paths]
    bad_prefixes = [case.filename for case in cases if case.category not in {"i", "n", "y"}]
    if bad_prefixes:
        raise SystemExit(f"unexpected JSONTestSuite prefixes: {bad_prefixes}")
    return cases


def read_case(path: Path) -> Case:
    raw = path.read_bytes()
    support, reason, text = classify(path.name, raw)
    return Case(
        filename=path.name,
        category=path.name[0],
        raw=raw,
        support=support,
        reason=reason,
        text=text,
    )


def classify(filename: str, raw: bytes) -> tuple[str, str, str | None]:
    lower = filename.lower()
    if "100000" in lower or "500_nested" in lower or len(raw) > 50_000:
        return ("stress", "large_or_deep_input", None)
    if (
        "utf16" in lower
        or "utf-16" in lower
        or raw.startswith(b"\xff\xfe")
        or raw.startswith(b"\xfe\xff")
    ):
        return ("byte_only", "utf16_input", None)
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return ("byte_only", "invalid_utf8", None)
    return ("utf8_text", "", text)


def write_manifest(path: Path, cases: list[Case]) -> None:
    unsupported = [case for case in cases if case.support != "utf8_text"]
    lines = header("json_testsuite_manifest.mbt")
    lines += [
        "// Unsupported or separated cases:",
        "// | filename | support | reason |",
        "// | --- | --- | --- |",
    ]
    for case in unsupported:
        lines.append(f"// | {case.filename} | {case.support} | {case.reason} |")
    lines += [
        "",
        "///|",
        "priv enum JsonTestSuiteCategory {",
        "  Accept",
        "  Reject",
        "  AcceptOrReject",
        "}",
        "",
        "///|",
        "priv enum JsonTestSuiteSupport {",
        "  Utf8Text",
        "  ByteOnly(String)",
        "  Stress(String)",
        "}",
        "",
        "///|",
        "priv struct JsonTestSuiteCase {",
        "  filename : String",
        "  category : JsonTestSuiteCategory",
        "  byte_length : Int",
        "  sha256 : String",
        "  source_url : String",
        "  support : JsonTestSuiteSupport",
        "  payload_base64 : String",
        "}",
        "",
        "///|",
        f'let json_testsuite_upstream_commit = "{UPSTREAM_COMMIT}"',
        "",
        "///|",
        "let json_testsuite_cases : Array[JsonTestSuiteCase] = [",
    ]
    for case in cases:
        support_expr = {
            "utf8_text": "JsonTestSuiteSupport::Utf8Text",
            "byte_only": f'JsonTestSuiteSupport::ByteOnly("{case.reason}")',
            "stress": f'JsonTestSuiteSupport::Stress("{case.reason}")',
        }[case.support]
        payload_expr = moon_string_expr_lines(
            base64.b64encode(case.raw).decode("ascii"),
            prefix="    payload_base64: ",
            continuation_indent="    ",
            trailing=",",
        )
        lines += [
            "  JsonTestSuiteCase::{",
            f'    filename: "{case.filename}",',
            f"    category: JsonTestSuiteCategory::{case.policy},",
            f"    byte_length: {len(case.raw)},",
            f'    sha256: "{hashlib.sha256(case.raw).hexdigest()}",',
            f'    source_url: "{case.source_url}",',
            f"    support: {support_expr},",
            *payload_expr,
            "  },",
        ]
    counts = count_cases(cases)
    lines += [
        "]",
        "",
        "///|",
        'test "json_testsuite manifest metadata" {',
        f'  assert_eq(json_testsuite_upstream_commit, "{UPSTREAM_COMMIT}")',
        f"  assert_eq(json_testsuite_cases.length(), {len(cases)})",
        "  let mut accepts = 0",
        "  let mut rejects = 0",
        "  let mut accept_or_rejects = 0",
        "  let mut utf8_text = 0",
        "  let mut byte_only = 0",
        "  let mut stress = 0",
        "  for case in json_testsuite_cases {",
        "    ignore(case.filename)",
        "    ignore(case.byte_length)",
        "    ignore(case.sha256)",
        "    ignore(case.source_url)",
        "    ignore(case.payload_base64)",
        "    match case.category {",
        "      JsonTestSuiteCategory::Accept => accepts += 1",
        "      JsonTestSuiteCategory::Reject => rejects += 1",
        "      JsonTestSuiteCategory::AcceptOrReject => accept_or_rejects += 1",
        "    }",
        "    match case.support {",
        "      JsonTestSuiteSupport::Utf8Text => utf8_text += 1",
        "      JsonTestSuiteSupport::ByteOnly(reason) => {",
        "        ignore(reason)",
        "        byte_only += 1",
        "      }",
        "      JsonTestSuiteSupport::Stress(reason) => {",
        "        ignore(reason)",
        "        stress += 1",
        "      }",
        "    }",
        "  }",
        f"  assert_eq(accepts, {counts['y']})",
        f"  assert_eq(rejects, {counts['n']})",
        f"  assert_eq(accept_or_rejects, {counts['i']})",
        f"  assert_eq(utf8_text, {counts['utf8_text']})",
        f"  assert_eq(byte_only, {counts['byte_only']})",
        f"  assert_eq(stress, {counts['stress']})",
        "}",
        "",
    ]
    path.write_text("\n".join(lines), encoding="utf-8")


def write_tests(path: Path, cases: list[Case], helper: str) -> None:
    lines = header(path.name)
    for case in cases:
        assert case.text is not None
        lines += [
            "///|",
            f'test "json_testsuite {case.name}" {{',
            *moon_string_expr_lines(
                case.text,
                prefix="  let input = ",
                continuation_indent="    ",
            ),
            f'  {helper}("{case.filename}", input)',
            "}",
            "",
        ]
    path.write_text("\n".join(lines), encoding="utf-8")


def header(filename: str) -> list[str]:
    return [
        "// Generated by tools/update_json_testsuite.py; do not edit by hand.",
        f"// Source: {UPSTREAM_REPO}/tree/{UPSTREAM_COMMIT}/test_parsing",
        "// Upstream license: MIT License, Copyright (c) 2016 Nicolas Seriot.",
        f"// File: {filename}",
        "",
    ]


def count_cases(cases: list[Case]) -> dict[str, int]:
    return {
        "y": sum(1 for case in cases if case.category == "y"),
        "n": sum(1 for case in cases if case.category == "n"),
        "i": sum(1 for case in cases if case.category == "i"),
        "utf8_text": sum(1 for case in cases if case.support == "utf8_text"),
        "byte_only": sum(1 for case in cases if case.support == "byte_only"),
        "stress": sum(1 for case in cases if case.support == "stress"),
    }


def moon_string_expr_lines(
    text: str,
    *,
    prefix: str,
    continuation_indent: str,
    trailing: str = "",
) -> list[str]:
    chunks: list[str] = []
    current = ""
    for char in text:
        escaped = moon_escape_char(char)
        if current and len(current) + len(escaped) > MAX_LITERAL_CHUNK:
            chunks.append(current)
            current = escaped
        else:
            current += escaped
    chunks.append(current)
    lines = []
    for index, chunk in enumerate(chunks):
        line_prefix = prefix if index == 0 else continuation_indent
        line_suffix = trailing if index == len(chunks) - 1 else " +"
        lines.append(f'{line_prefix}"{chunk}"{line_suffix}')
    return lines


def moon_escape_char(char: str) -> str:
    codepoint = ord(char)
    if char == "\\":
        return "\\\\"
    if char == '"':
        return '\\"'
    if char == "\n":
        return "\\n"
    if char == "\r":
        return "\\r"
    if char == "\t":
        return "\\t"
    if char == "\b":
        return "\\b"
    if char == "\f":
        return "\\u{0c}"
    if codepoint < 0x20 or codepoint == 0x7F or codepoint >= 0x80:
        return "\\u{" + format(codepoint, "x") + "}"
    return char


def print_summary(cases: list[Case]) -> None:
    print(f"generated from {len(cases)} JSONTestSuite cases at {UPSTREAM_COMMIT}")
    for category in ("y", "n", "i"):
        total = sum(1 for case in cases if case.category == category)
        active = sum(
            1
            for case in cases
            if case.category == category and case.support == "utf8_text"
        )
        print(f"{category}: {active} active / {total} total")
    for support in ("byte_only", "stress"):
        count = sum(1 for case in cases if case.support == support)
        print(f"{support}: {count}")


if __name__ == "__main__":
    main()
