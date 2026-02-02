#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scan sibling repositories for TODO-like comments and aggregate them into super/TODO.md (and optional JSON).

Features:
- Detects TODO/FIXME/BUG with optional tag payloads: TODO, TODO(@user), TODO(#123), TODO(Peter)
- Skips common vendor/build/binary directories and files
- Supports include extensions filter
- Attempts to build clickable GitHub links to exact line if a remote is configured
- Emits Markdown and optional JSON
- Returns non-zero exit if critical TODOs are found (for CI gating)
"""

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Reasonable defaults
DEFAULT_MARKERS = ["TODO", "FIXME", "BUG"]
DEFAULT_EXCLUDED_DIRS = {
    ".git", ".hg", ".svn", ".idea", ".vscode",
    "node_modules", "dist", "build", "out", "target", "__pycache__", ".venv", "venv",
    ".next", ".turbo", ".tox", ".mypy_cache", ".pytest_cache",
}
DEFAULT_INCLUDE_EXTS = {  # include some common code/text extensions
    ".py", ".kt", ".java", ".go", ".ts", ".tsx", ".js", ".jsx",
    ".rb", ".rs", ".c", ".h", ".cpp", ".hpp", ".cs",
    ".yaml", ".yml", ".json", ".sh", ".bash", ".zsh",
    ".md", ".txt", ".toml", ".ini", ".tf", ".tfvars", ".dockerfile", "dockerfile",
}
# Heuristic: words that make a TODO "critical" (fail CI)
CRITICAL_WORDS = {"urgent", "blocker", "security", "prod", "production", "p0", "sev1", "severe"}

LINE_LINK_TEMPLATES = [
    # GitHub, GitLab, Azure DevOps style patterns derived from common remotes
    # remote like: git@github.com:org/repo.git or https://github.com/org/repo.git
    ("github.com", "https://{host}/{orgrepo}/blob/{branch}/{path}#L{line}"),
    ("gitlab.com", "https://{host}/{orgrepo}/-/blob/{branch}/{path}#L{line}"),
    # Azure DevOps (simple link that lands near the file)
    ("dev.azure.com", "https://{host}/{orgrepo}/_git/{repo}?path=/{path}&version=GB{branch}&line={line}"),
]

TODO_PATTERN = re.compile(
    r"""(?xi)
    (?P<prefix>^|\s|[^\w])                               # boundary
    (?P<marker>TODO|FIXME|BUG)                           # marker
    (?:\s*[:\-\s]\s*|\s*\(\s*(?P<tag>[^)]+)\s*\)\s*[:\-]?\s*)?  # optional (: or - or (tag))
    (?P<text>.*?)$                                       # remainder of the line (non-greedy)
    """
)

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Aggregate TODOs across sibling repositories into a Markdown dashboard.")
    parser.add_argument("--root", default="..", help="Root directory containing the repos (defaults to parent of 'super').")
    parser.add_argument("--repos", default="", help="Comma-separated list of repo names to scan; defaults to all siblings except 'super'.")
    parser.add_argument("--out-md", default="TODO.md", help="Output Markdown path (relative to current working directory).")
    parser.add_argument("--out-json", default="", help="Optional JSON output path.")
    parser.add_argument("--marker", default=",".join(DEFAULT_MARKERS), help="Comma-separated markers to search for (e.g., TODO,FIXME,BUG).")
    parser.add_argument("--include-ext", default=",".join(sorted(DEFAULT_INCLUDE_EXTS)), help="Comma-separated file extensions to include.")
    parser.add_argument("--extra-exclude", default="", help="Comma-separated extra directories to exclude.")
    parser.add_argument("--no-remote-links", action="store_true", help="Disable building remote links to lines.")
    parser.add_argument("--branch", default="", help="Preferred branch name for links (e.g., main). If empty, try to detect per-repo.")
    return parser.parse_args()

def is_binary_file(path: Path, sample_size: int = 1024) -> bool:
    try:
        with path.open("rb") as f:
            chunk = f.read(sample_size)
        if b"\x00" in chunk:
            return True
        # Heuristic: too many non-text bytes
        textchars = bytearray({7, 8, 9, 10, 12, 13, 27} | set(range(0x20, 0x100)))
        return bool(chunk.translate(None, textchars))
    except Exception:
        # If unreadable, treat as binary to be safe
        return True

def detect_remote_info(repo_dir: Path) -> Optional[Dict[str, str]]:
    """Return dict with host, orgrepo, repo, default_branch (best-effort)."""
    try:
        def _git(cmd: List[str]) -> str:
            return subprocess.check_output(cmd, cwd=str(repo_dir), stderr=subprocess.DEVNULL).decode().strip()

        remote_url = _git(["git", "remote", "get-url", "origin"])
        # Normalize
        if remote_url.endswith(".git"):
            remote_url = remote_url[:-4]

        host, orgrepo, repo_name = None, None, None

        if remote_url.startswith("git@"):
            # git@github.com:org/repo
            _, rest = remote_url.split("@", 1)
            host, path = rest.split(":", 1)
            orgrepo = path
        elif remote_url.startswith("https://") or remote_url.startswith("http://"):
            # https://github.com/org/repo
            parts = remote_url.split("/")
            # ['', 'https:', '', 'github.com', 'org', 'repo']
            if len(parts) >= 5:
                host = parts[2]
                orgrepo = "/".join(parts[3:5])
        else:
            return None

        if not host or not orgrepo:
            return None

        repo_name = orgrepo.split("/")[-1]

        # Detect default or current branch
        try:
            default_branch = _git(["git", "symbolic-ref", "refs/remotes/origin/HEAD"])
            default_branch = default_branch.split("/")[-1]
        except Exception:
            try:
                default_branch = _git(["git", "rev-parse", "--abbrev-ref", "HEAD"])
            except Exception:
                default_branch = "main"

        return {"host": host, "orgrepo": orgrepo, "repo": repo_name, "default_branch": default_branch}
    except Exception:
        return None

def build_line_link(remote: Dict[str, str], branch: str, rel_path: str, line_no: int) -> Optional[str]:
    host = remote.get("host")
    orgrepo = remote.get("orgrepo")
    repo = remote.get("repo")
    for h, template in LINE_LINK_TEMPLATES:
        if h in host:
            try:
                return template.format(host=host, orgrepo=orgrepo, repo=repo, branch=branch, path=rel_path, line=line_no)
            except Exception:
                return None
    return None

def should_exclude_dir(dirname: str, excluded: set) -> bool:
    # Also exclude hidden directories starting with dot unless explicitly included
    return dirname in excluded or (dirname.startswith(".") and dirname not in {"."})

def collect_files(repo_dir: Path, include_exts: set, excluded_dirs: set) -> List[Path]:
    results = []
    for root, dirs, files in os.walk(repo_dir):
        # Prune directories early
        dirs[:] = [d for d in dirs if not should_exclude_dir(d, excluded_dirs)]
        for f in files:
            p = Path(root) / f
            ext = p.suffix.lower() if p.suffix else p.name.lower()  # allow matching 'dockerfile'
            if ext in include_exts and not is_binary_file(p):
                results.append(p)
    return results

def scan_file(path: Path, markers: List[str]) -> List[Dict]:
    todos = []
    try:
        with path.open("r", encoding="utf-8", errors="replace") as f:
            for i, line in enumerate(f, start=1):
                m = TODO_PATTERN.search(line)
                if not m:
                    continue
                marker = m.group("marker")
                if marker not in markers:
                    continue
                text = m.group("text").strip()
                tag = m.group("tag").strip() if m.group("tag") else ""
                todos.append({
                    "line": i,
                    "marker": marker,
                    "tag": tag,
                    "text": text,
                    "preview": line.strip(),
                })
    except Exception as e:
        # unreadable file; skip
        pass
    return todos

def looks_critical(text: str) -> bool:
    t = text.lower()
    return any(word in t for word in CRITICAL_WORDS)

def main():
    args = parse_args()
    root = Path(args.root).resolve()
    super_dir = Path.cwd().resolve()
    if super_dir.name != "super":
        # Not a hard requirement, but warn
        print("⚠️  Warning: You are not running from a 'super' directory. Outputs will be relative to CWD.", file=sys.stderr)

    include_exts = {e.strip().lower() for e in args.include_ext.split(",") if e.strip()}
    markers = [m.strip().upper() for m in args.marker.split(",") if m.strip()]
    excluded_dirs = set(DEFAULT_EXCLUDED_DIRS)
    if args.extra_exclude:
        excluded_dirs |= {d.strip() for d in args.extra_exclude.split(",") if d.strip()}

    # Determine repos to scan
    if args.repos:
        repos = [n.strip() for n in args.repos.split(",") if n.strip()]
    else:
        # All directories in root except 'super'
        repos = [p.name for p in root.iterdir() if p.is_dir() and p.name != "super"]

    aggregated: Dict[str, List[Dict]] = {}
    critical_found = False

    for repo_name in sorted(repos):
        repo_dir = root / repo_name
        if not repo_dir.is_dir():
            continue

        remote_info = None if args.no_remote_links else detect_remote_info(repo_dir)
        branch = args.branch or (remote_info["default_branch"] if remote_info else "main")

        files = collect_files(repo_dir, include_exts, excluded_dirs)
        repo_rel_root = os.path.relpath(repo_dir, root)

        for file_path in files:
            rel_from_repo = os.path.relpath(file_path, repo_dir)
            entries = scan_file(file_path, markers)
            for entry in entries:
                line_no = entry["line"]
                link = None
                if remote_info and not args.no_remote_links:
                    rel_for_link = rel_from_repo.replace("\\", "/")
                    link = build_line_link(remote_info, branch, rel_for_link, line_no)

                if looks_critical(entry["text"]):
                    critical_found = True

                aggregated.setdefault(repo_name, []).append({
                    "file": rel_from_repo.replace("\\", "/"),
                    "line": line_no,
                    "marker": entry["marker"],
                    "tag": entry["tag"],
                    "text": entry["text"],
                    "preview": entry["preview"],
                    "link": link or "",
                    "repo": repo_name,
                })

    # Sort within repos: by marker then file then line
    for repo_name in aggregated:
        aggregated[repo_name].sort(key=lambda x: (x["marker"], x["file"], x["line"]))

    # Write Markdown
    md_out = Path(args.out_md)
    md_lines = []
    md_lines.append(f"# Consolidated TODOs")
    md_lines.append("")
    md_lines.append(f"- Generated: {datetime.utcnow().isoformat(timespec='seconds')}Z")
    md_lines.append(f"- Root scanned: `{root}`")
    md_lines.append(f"- Repos scanned: {', '.join(repos) if repos else '(none)' }")
    md_lines.append(f"- Markers: {', '.join(markers)}")
    md_lines.append("")

    total_count = sum(len(v) for v in aggregated.values())
    md_lines.append(f"**Total items:** {total_count}")
    if total_count == 0:
        md_lines.append("")
        md_lines.append("> 🎉 No TODO-like markers found in the scanned repositories.")
    md_lines.append("")

    for repo_name in sorted(aggregated.keys()):
        items = aggregated[repo_name]
        md_lines.append(f"## {repo_name} ({len(items)})")
        md_lines.append("")
        # Sub-group by marker for readability
        by_marker: Dict[str, List[Dict]] = {}
        for it in items:
            by_marker.setdefault(it["marker"], []).append(it)

        for marker in sorted(by_marker.keys()):
            md_lines.append(f"### {marker} ({len(by_marker[marker])})")
            md_lines.append("")
            for it in by_marker[marker]:
                tag_str = f" **[{it['tag']}]**" if it["tag"] else ""
                location = f"`{it['file']}:{it['line']}`"
                if it["link"]:
                    location = f"{it['link']}"
                preview = it["text"] or it["preview"]
                md_lines.append(f"- {location}{tag_str} — {preview}")
            md_lines.append("")
        md_lines.append("")

    md_out.write_text("\n".join(md_lines), encoding="utf-8")

    # Optional JSON
    if args.out_json:
        json_out = Path(args.out_json)
        # Flatten with repo in each row
        flat: List[Dict] = []
        for repo_name, items in aggregated.items():
            for it in items:
                flat.append(it)
        json_out.write_text(json.dumps({
            "generated_utc": datetime.utcnow().isoformat(timespec="seconds") + "Z",
            "root": str(root),
            "repos": repos,
            "markers": markers,
            "count": len(flat),
            "items": flat,
        }, indent=2), encoding="utf-8")

    # Summary to stdout
    print(f"🧾 Wrote Markdown: {md_out} (items: {total_count})")
    if args.out_json:
        print(f"🧾 Wrote JSON: {args.out_json}")
    if critical_found:
        print("❗Critical TODOs detected (keywords: " + ", ".join(sorted(CRITICAL_WORDS)) + ")", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
