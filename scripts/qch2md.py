#!/usr/bin/env python3
"""Extract QML type pages from local Qt .qch files into the nvim qml-docs store.

Reads already-installed docs under /usr/share/doc/qt6/*.qch (qt6-doc package).
Does not fetch from the network.

Usage:
  python3 ~/.config/nvim/scripts/qch2md.py                  # default shapes set
  python3 ~/.config/nvim/scripts/qch2md.py --types Item Text
  python3 ~/.config/nvim/scripts/qch2md.py --types MouseArea --json
  # then :lua require("qml_docs").reload()  (auto-hover does this for you)
"""
from __future__ import annotations

import argparse
import html as htmllib
import json
import os
import re
import sqlite3
import sys
import zlib
from pathlib import Path

DOC_ROOT = Path("/usr/share/doc/qt6")
OUT = Path.home() / ".local/share/nvim/qml-docs"

DEFAULT_TYPES = [
    "Shape",
    "ShapePath",
    "Path",
    "PathLine",
    "PathArc",
    "PathCubic",
    "PathQuad",
    "PathMove",
    "PathSvg",
    "PathAngleArc",
    "PathCurve",
    "PathElement",
    "PathPolyline",
    "PathRectangle",
    "PathAttribute",
    "LinearGradient",
    "RadialGradient",
]


def _text(fragment: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", fragment)).strip()


def _cells(fragment: str) -> str:
    cells = [
        _text(c).rstrip(":")
        for c in re.findall(r"(?s)<td[^>]*>(.*?)</td>", fragment)
    ]
    cells = [c for c in cells if c]
    return ": ".join(cells) if cells else _text(fragment)


def to_markdown(html: str) -> str:
    html = re.sub(r"(?s)<script.*?</script>|<style.*?</style>", "", html)
    html = re.sub(r"(?s)<!--.*?-->", "", html)
    html = re.sub(r"(?s)<title>.*?</title>", "", html)
    start = html.find('<div class="content mainContent">')
    if start > 0:
        html = html[start:]
    html = re.sub(
        r'(?s)<div class="sidebar">.*?<div class="sidebar-content"[^>]*></div>',
        "",
        html,
    )
    html = re.sub(r'(?s)<div class="toc">.*?</div>', "", html)
    html = re.sub(r'(?s)<div class="footer">.*', "", html)

    blocks: list[str] = []

    def stash(m: re.Match) -> str:
        body = htmllib.unescape(re.sub(r"<[^>]+>", "", m.group(1))).strip("\n")
        blocks.append(body)
        return f"\x00CODE{len(blocks) - 1}\x00"

    html = re.sub(r"(?s)<pre[^>]*>(.*?)</pre>", stash, html)
    html = re.sub(
        r"(?s)<h1[^>]*>(.*?)</h1>", lambda m: f"\n# {_text(m.group(1))}\n", html
    )
    html = re.sub(
        r"(?s)<h2[^>]*>(.*?)</h2>", lambda m: f"\n## {_text(m.group(1))}\n", html
    )
    html = re.sub(
        r"(?s)<h3[^>]*>(.*?)</h3>", lambda m: f"\n### {_text(m.group(1))}\n", html
    )
    html = re.sub(
        r"(?s)<li[^>]*>(.*?)</li>", lambda m: f"\n- {_text(m.group(1))}", html
    )
    html = re.sub(r"(?s)</?table[^>]*>", "\n", html)
    html = re.sub(
        r"(?s)<tr[^>]*>(.*?)</tr>", lambda m: "\n- " + _cells(m.group(1)), html
    )
    html = re.sub(
        r"(?s)<p[^>]*>(.*?)</p>", lambda m: f"\n{_text(m.group(1))}\n", html
    )
    html = re.sub(r"(?s)<br\s*/?>", "  \n", html)
    html = re.sub(r"(?s)<[^>]+>", "", html)
    html = htmllib.unescape(html)
    html = html.replace(" More...", "")

    for i, block in enumerate(blocks):
        html = html.replace(f"\x00CODE{i}\x00", f"\n```qml\n{block}\n```\n")

    lines, out = html.split("\n"), []
    for line in lines:
        line = re.sub(r"[ \t]+$", "", line)
        if "List of all members" in line:
            continue
        if not line.strip() and out and not out[-1].strip():
            continue
        out.append(line)
    text = "\n".join(out).strip()
    for _ in range(6):
        text = re.sub(r"(?m)^(- .*)\n\n(?=- )", r"\1\n", text)
    return text


def load_index(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text())
        return data if isinstance(data, list) else []
    except json.JSONDecodeError:
        return []


def qch_files(doc_root: Path, explicit: str | None) -> list[Path]:
    if explicit:
        p = Path(explicit)
        return [p] if p.is_file() else []
    if not doc_root.is_dir():
        return []
    return sorted(doc_root.glob("*.qch"))


def find_page(
    qchs: list[Path], qml_type: str
) -> tuple[str, Path, str] | None:
    """Return (html, qch_path, filename) for the best matching type page."""
    needle = qml_type.lower()
    # Prefer exact module pages over "-members" and designhelpers noise.
    patterns = [
        rf"^qml-.+-{re.escape(needle)}\.html$",
        rf"^qml-{re.escape(needle)}\.html$",
    ]

    for qch in qchs:
        try:
            db = sqlite3.connect(f"file:{qch}?mode=ro", uri=True)
        except sqlite3.Error:
            continue
        try:
            names = [
                r[0]
                for r in db.execute("select Name from FileNameTable").fetchall()
            ]
            match = None
            for pat in patterns:
                cands = [
                    n
                    for n in names
                    if re.match(pat, n, re.I)
                    and "members" not in n.lower()
                    and "obsolete" not in n.lower()
                    and "example" not in n.lower()
                ]
                if not cands:
                    continue
                # Prefer shorter path (less nested module prefix noise), then
                # shapes/qtquick over obscure modules.
                def score(n: str) -> tuple:
                    nl = n.lower()
                    return (
                        0 if "qtquick-shapes" in nl else 1,
                        0 if "qtquick-" in nl and "qtquick3d" not in nl else 1,
                        len(n),
                        n,
                    )

                cands.sort(key=score)
                match = cands[0]
                break
            if not match:
                continue
            row = db.execute(
                "select FileId from FileNameTable where Name = ?", (match,)
            ).fetchone()
            blob = db.execute(
                "select Data from FileDataTable where Id = ?", (row[0],)
            ).fetchone()[0]
            html = zlib.decompress(blob[4:]).decode("utf-8", "replace")
            return html, qch, match
        finally:
            db.close()
    return None


def doc_url(filename: str, qml_type: str) -> str:
    # filename like qml-qtquick-shapes-shapepath.html → doc.qt.io slug
    base = filename.rsplit(".", 1)[0]
    return f"https://doc.qt.io/qt-6/{base}.html"


def extract_one(
    qml_type: str, qchs: list[Path], out_dir: Path
) -> dict:
    found = find_page(qchs, qml_type)
    if not found:
        return {"ok": False, "type_name": qml_type, "error": "not found in local qch"}
    html, qch, filename = found
    md = to_markdown(html)
    if not md.strip():
        return {"ok": False, "type_name": qml_type, "error": "empty page"}

    body_file = f"{qml_type}.md"
    (out_dir / body_file).write_text(md + "\n", encoding="utf-8")
    brief_m = re.search(r"^# .*?\n\n(.+?)(?:\n|$)", md, re.M)
    row = {
        "id": f"QML.{qml_type}",
        "type_name": qml_type,
        "summary": (brief_m.group(1).strip() if brief_m else "")[:200],
        "body_file": body_file,
        "chars": len(md),
        "url": doc_url(filename, qml_type),
        "source": f"qch:{qch.name}",
    }
    return {
        "ok": True,
        "type_name": qml_type,
        "chars": len(md),
        "qch": qch.name,
        "file": filename,
        "row": row,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--types", nargs="*", default=None)
    ap.add_argument("--qch", default=None, help="Single .qch path (default: all under doc root)")
    ap.add_argument("--doc-root", default=str(DOC_ROOT))
    ap.add_argument("--out", default=str(OUT))
    ap.add_argument(
        "--json",
        action="store_true",
        help="Print one JSON object per type (for nvim auto-extract)",
    )
    args = ap.parse_args()

    types = args.types or DEFAULT_TYPES
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    qchs = qch_files(Path(args.doc_root), args.qch)
    if not qchs:
        msg = {"ok": False, "error": f"no qch under {args.doc_root}"}
        if args.json:
            print(json.dumps(msg))
        else:
            print(msg["error"], file=sys.stderr)
        return 2

    existing = load_index(out_dir / "index.json")
    # Replace only the types we (re)extract; keep everything else including other qch.
    type_set = set(types)
    kept = [r for r in existing if r.get("type_name") not in type_set]
    rows = list(kept)
    written = 0
    results = []

    for qml_type in types:
        result = extract_one(qml_type, qchs, out_dir)
        results.append(result)
        if result.get("ok") and result.get("row"):
            rows.append(result["row"])
            written += 1
            if not args.json:
                print(
                    f"{qml_type:24} {result['chars']:6} chars  "
                    f"[{result.get('qch')}] {result.get('file')}"
                )
        elif not args.json:
            print(f"missing: {qml_type}", file=sys.stderr)

    (out_dir / "index.json").write_text(
        json.dumps(rows, indent=2) + "\n", encoding="utf-8"
    )

    if args.json:
        # Single type → one object; multi → array.
        payload = results[0] if len(results) == 1 else results
        # Strip heavy row from wire if present (index already written).
        def slim(r: dict) -> dict:
            return {k: v for k, v in r.items() if k != "row"}

        if isinstance(payload, list):
            print(json.dumps([slim(r) for r in payload]))
        else:
            print(json.dumps(slim(payload)))

    if not args.json:
        print(f"\n{written}/{len(types)} extracted, {len(kept)} other preserved -> {out_dir}")

    if written == 0:
        return 1
    if written < len(types):
        return 0  # partial ok
    return 0


if __name__ == "__main__":
    sys.exit(main())
