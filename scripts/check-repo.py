#!/usr/bin/env python3
"""Repository checks that need no cloud access.

1. House style in prose and config: no em or en dashes, straight quotes only.
2. Nothing that belongs on one machine has been committed: state files,
   variable files (other than *.example), private keys, or AWS access key IDs.

Run from the repository root: python3 scripts/check-repo.py
"""
import re
import subprocess
import sys

TEXT_SUFFIXES = (".md", ".tf", ".yaml", ".yml", ".json", ".example", ".py")
FORBIDDEN_NAMES = (
    re.compile(r"\.tfstate(\.|$)"),
    re.compile(r"\.tfplan$"),
    re.compile(r"(^|/)terraform\.tfvars(\.json)?$"),
    re.compile(r"\.auto\.tfvars(\.json)?$"),
    re.compile(r"\.(pem|key)$"),
    re.compile(r"(^|/)\.env$"),
)
SECRET_PATTERNS = (
    ("AWS access key ID", re.compile(r"\b(AKIA|ASIA)[0-9A-Z]{16}\b")),
    ("private key block", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
)
BAD_CHARS = {
    "—": "em dash",
    "–": "en dash",
    "‘": "curly single quote",
    "’": "curly single quote",
    "“": "curly double quote",
    "”": "curly double quote",
}


def tracked_files():
    out = subprocess.run(["git", "ls-files"], capture_output=True, text=True, check=True).stdout
    return [f for f in out.splitlines() if f]


def main():
    problems = []
    for path in tracked_files():
        for pattern in FORBIDDEN_NAMES:
            if pattern.search(path):
                problems.append(f"{path}: this kind of file must not be committed")
        if not path.endswith(TEXT_SUFFIXES) or path == "LICENSE":
            continue
        try:
            text = open(path, encoding="utf-8").read()
        except (OSError, UnicodeDecodeError):
            continue
        for number, line in enumerate(text.splitlines(), 1):
            for char, name in BAD_CHARS.items():
                if char in line:
                    problems.append(f"{path}:{number}: {name}")
            if path != "scripts/check-repo.py":
                for label, pattern in SECRET_PATTERNS:
                    if pattern.search(line):
                        problems.append(f"{path}:{number}: looks like a {label}")
    if problems:
        print("\n".join(problems))
        print(f"\n{len(problems)} problem(s) found.")
        return 1
    print("Repository checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
