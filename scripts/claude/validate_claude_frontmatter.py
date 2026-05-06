#!/usr/bin/env python3
"""validate_claude_frontmatter.py — Validate frontmatter in .claude/commands/ and .claude/skills/ files.

Checks that command files (`.claude/commands/**/*.md`) and skill files (`.claude/skills/**/SKILL.md`)
have valid YAML frontmatter with expected fields.

Modes:
  baseline (default): missing frontmatter = warning, broken frontmatter = error
  --strict:           missing frontmatter = error

Skill-specific checks (only when SKILL.md has frontmatter):
  - `name` field is required and must match the parent directory name
  - `description` field is required (multiline `description: |` block scalar is OK —
    only key presence is asserted)

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

# Recommended (informational) fields per file role
COMMAND_RECOMMENDED_FIELDS = {"description", "args"}
SKILL_REQUIRED_FIELDS = {"name", "description"}


def is_skill_file(filepath: Path) -> bool:
    """Detect `.claude/skills/<dir>/SKILL.md` pattern (parent dir name = skill name)."""
    parts = filepath.parts
    return (
        filepath.name == "SKILL.md"
        and len(parts) >= 3
        and parts[-3] == "skills"
    )


def parse_frontmatter(content: str) -> tuple[dict | None, str | None]:
    """Parse YAML frontmatter from file content.

    Supports multiline block scalar values (`key: |` followed by indented continuation lines).
    Only key presence is recorded for block-scalar values — the parser treats them as truthy.

    Returns:
        (fields_dict, None) on success
        (None, error_message) on failure
        (None, None) if no frontmatter present
    """
    m = FRONTMATTER_RE.match(content)
    if not m:
        return None, None

    yaml_text = m.group(1)

    fields: dict = {}
    in_block_scalar_for: str | None = None  # active block-scalar key (if any)

    for line in yaml_text.split("\n"):
        # Continuation of a block scalar: any indented (or empty) line belongs to it
        if in_block_scalar_for is not None:
            if line == "" or line.startswith((" ", "\t")):
                continue  # absorb continuation
            in_block_scalar_for = None  # dedent → block scalar ends; fall through to parse line

        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if ":" not in stripped:
            continue

        key, _, value = stripped.partition(":")
        key = key.strip()
        value = value.strip()

        # Detect block scalar opener (`key: |` or `key: >`, optionally with chomping/indicator)
        if value in ("|", ">") or value.startswith(("|", ">")):
            fields[key] = value
            in_block_scalar_for = key
            continue

        # Strip surrounding quotes if present
        if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
            value = value[1:-1]
        fields[key] = value

    return fields, None


def validate_file(filepath: Path, strict: bool) -> tuple[int, int, list[str]]:
    """Validate a single command or skill file.

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

    skill_mode = is_skill_file(filepath)

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
        messages.append(f"❌ {filepath}: unclosed frontmatter block")
        return 1, 0, messages

    if skill_mode:
        # Skill-specific assertions: required name + description, name matches dir
        missing_required = SKILL_REQUIRED_FIELDS - set(fields.keys())
        if missing_required:
            messages.append(
                f"❌ {filepath}: missing required SKILL fields: {', '.join(sorted(missing_required))}"
            )
            errors += 1
            return errors, warnings, messages

        parent_dir = filepath.parent.name
        name_value = fields.get("name", "")
        if name_value != parent_dir:
            messages.append(
                f"❌ {filepath}: SKILL name '{name_value}' does not match parent directory '{parent_dir}'"
            )
            errors += 1
            return errors, warnings, messages

        messages.append(f"✅ {filepath}: SKILL frontmatter OK (name={name_value})")
        return errors, warnings, messages

    # Command mode: warn on missing recommended fields
    missing = COMMAND_RECOMMENDED_FIELDS - set(fields.keys())
    if missing:
        messages.append(
            f"⚠️  {filepath}: missing recommended fields: {', '.join(sorted(missing))}"
        )
        warnings += 1
    else:
        messages.append(f"✅ {filepath}: frontmatter OK")

    return errors, warnings, messages


def collect_files(target_dir: Path) -> list[Path]:
    """Collect markdown files for a target directory.

    `.claude/skills/` → only SKILL.md files
    `.claude/commands/` → all .md files (excluding README.md)
    """
    if not target_dir.is_dir():
        return []
    if target_dir.name == "skills":
        return sorted(target_dir.rglob("SKILL.md"))
    return sorted(
        f for f in target_dir.rglob("*.md") if f.name.upper() != "README.MD"
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate Claude commands and skills frontmatter"
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat missing frontmatter as error",
    )
    parser.add_argument(
        "--dir",
        action="append",
        default=None,
        help=(
            "Directory to scan (repeatable). "
            "Default: both .claude/commands and .claude/skills"
        ),
    )
    args = parser.parse_args()

    if args.dir is None:
        target_dirs = [Path(".claude/commands"), Path(".claude/skills")]
    else:
        target_dirs = [Path(d) for d in args.dir]

    md_files: list[Path] = []
    for d in target_dirs:
        if not d.is_dir():
            print(f"⚠️  Directory not found, skipping: {d}")
            continue
        md_files.extend(collect_files(d))

    if not md_files:
        print(f"⚠️  No files found in: {', '.join(str(d) for d in target_dirs)}")
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
