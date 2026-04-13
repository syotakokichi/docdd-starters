#!/usr/bin/env python3
"""validate_claude_frontmatter.py — Validate frontmatter in .claude/commands/ files.

Checks that command files have valid YAML frontmatter with expected fields.

Modes:
  baseline (default): missing frontmatter = warning, broken frontmatter = error
  --strict:           missing frontmatter = error

Exit codes:
  0 — all checks passed (warnings OK in baseline mode)
  1 — one or more errors found
"""

import argparse
import re
import sys
from pathlib import Path

# Frontmatter pattern: match only the first --- ... --- block at file start
FRONTMATTER_RE = re.compile(r"\A---[ \t]*\n(.*?)\n---[ \t]*\n?", re.DOTALL)

# Fields we check for (informational, not required in baseline)
RECOMMENDED_FIELDS = {"description", "args"}


def parse_frontmatter(content: str) -> tuple[dict | None, str | None]:
    """Parse YAML frontmatter from file content.

    Returns:
        (fields_dict, None) on success
        (None, error_message) on failure
        (None, None) if no frontmatter present
    """
    m = FRONTMATTER_RE.match(content)
    if not m:
        return None, None

    yaml_text = m.group(1)

    # Simple key-value parser (avoids PyYAML dependency)
    fields: dict = {}
    for line in yaml_text.split("\n"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        # Remove quotes if present
        if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
            value = value[1:-1]
        fields[key] = value

    return fields, None


def validate_file(filepath: Path, strict: bool) -> tuple[int, int, list[str]]:
    """Validate a single command file.

    Returns:
        (errors, warnings, messages)
    """
    errors = 0
    warnings = 0
    messages: list[str] = []

    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        messages.append(f"❌ {filepath}: cannot read file: {e}")
        return 1, 0, messages

    if not content.strip():
        messages.append(f"⚠️  {filepath}: empty file")
        return 0, 1, messages

    # Check for frontmatter
    if not content.startswith("---"):
        if strict:
            messages.append(f"❌ {filepath}: no frontmatter (required in strict mode)")
            errors += 1
        else:
            messages.append(f"⚠️  {filepath}: no frontmatter")
            warnings += 1
        return errors, warnings, messages

    # Has frontmatter delimiter — try to parse
    fields, err = parse_frontmatter(content)

    if err:
        messages.append(f"❌ {filepath}: broken frontmatter: {err}")
        return 1, 0, messages

    if fields is None:
        # Started with --- but no closing ---
        messages.append(f"❌ {filepath}: unclosed frontmatter block")
        return 1, 0, messages

    # Frontmatter exists and parses — check recommended fields
    missing = RECOMMENDED_FIELDS - set(fields.keys())
    if missing:
        messages.append(
            f"⚠️  {filepath}: missing recommended fields: {', '.join(sorted(missing))}"
        )
        warnings += 1
    else:
        messages.append(f"✅ {filepath}: frontmatter OK")

    return errors, warnings, messages


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Claude commands frontmatter")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat missing frontmatter as error",
    )
    parser.add_argument(
        "--dir",
        default=".claude/commands",
        help="Directory to scan (default: .claude/commands)",
    )
    args = parser.parse_args()

    commands_dir = Path(args.dir)
    if not commands_dir.is_dir():
        print(f"❌ Directory not found: {commands_dir}")
        return 1

    # Find all .md files (excluding README.md)
    md_files = sorted(
        f for f in commands_dir.rglob("*.md") if f.name.upper() != "README.MD"
    )

    if not md_files:
        print(f"⚠️  No command files found in {commands_dir}")
        return 0

    total_errors = 0
    total_warnings = 0

    for filepath in md_files:
        errs, warns, msgs = validate_file(filepath, strict=args.strict)
        total_errors += errs
        total_warnings += warns
        for msg in msgs:
            print(msg)

    print(
        f"\nFrontmatter: {len(md_files)} files checked, "
        f"{total_errors} errors, {total_warnings} warnings"
    )

    return 1 if total_errors > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
