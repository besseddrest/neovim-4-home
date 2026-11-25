#!/usr/bin/env python3
"""Convert local Quickshell docs mirror HTML into nvim qml-docs store.

Reads type pages from:
  ~/.local/share/quickshell-docs/vX.Y.Z/docs/vX.Y.Z/types/<Module>/<Type>/index.html

Writes/merges:
  ~/.local/share/nvim/qml-docs/{Type.md,index.json}

Non-quickshell-docs rows are left alone. Rows with source
"quickshell-docs*" are replaced on re-run.

Usage:
  python3 ~/.config/nvim/scripts/qs2md.py
  python3 ~/.config/nvim/scripts/qs2md.py --version 0.3.2
  # then :lua require("qml_docs").reload()
"""
from __future__ import annotations

import argparse
import html as htmllib
import json
import os
import re
from pathlib import Path

HOME = Path.home()
MIRROR_ROOT = HOME / ".local/share/quickshell-docs"
OUT = HOME / ".local/share/nvim/qml-docs"
CANONICAL_BASE = "https://quickshell.org/docs"


def latest_version(root: Path) -> str:
    vers = []
    for p in root.iterdir() if root.is_dir() else []:
        if p.is_dir() and re.fullmatch(r"v\d+\.\d+\.\d+", p.name):
            vers.append(p.name[1:])
    if not vers:
        raise SystemExit(f"no version dirs under {root}")
    vers.sort(key=lambda v: tuple(int(x) for x in v.split(".")))
    return vers[-1]


def type_pages(version: str) -> list[tuple[str, str, Path]]:
    """Return (module, type_name, index.html path)."""
    base = MIRROR_ROOT / f"v{version}" / "docs" / f"v{version}" / "types"
    if not base.is_dir():
        raise SystemExit(f"missing types dir: {base}")
    out = []
    for mod_dir in sorted(base.iterdir()):
        if not mod_dir.is_dir() or mod_dir.name.startswith("."):
            continue
        module = mod_dir.name  # Quickshell, Quickshell.Io, …
        for type_dir in sorted(mod_dir.iterdir()):
            if not type_dir.is_dir():
                continue
            name = type_dir.name
            if name in ("index.html",) or not re.match(r"^[A-Z]", name):
                continue
            page = type_dir / "index.html"
            if page.is_file():
                out.append((module, name, page))
    return out


def _text(fragment: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", fragment)).strip()


def to_markdown(html: str, type_name: str, module: str) -> tuple[str, str]:
    """Return (markdown, summary)."""
    # Prefer the main docs pane; drop nav/toc chrome.
    m = re.search(
        r'<div class="docs-content typedocs-content">(.*?)(?:<div class="toc"|$)',
        html,
        re.S,
    )
    body = m.group(1) if m else html

    summary = ""
    sm = re.search(r'name="description" content="([^"]*)"', html)
    if sm:
        summary = htmllib.unescape(sm.group(1)).strip()

    # Title / superclass before stripping tags.
    title = type_name
    superclass = ""
    title_m = re.search(r'class="typedocs-title-text"[^>]*>(.*?)</h2>', body, re.S)
    if title_m:
        raw_title = _text(title_m.group(1))
        if ":" in raw_title:
            parts = [p.strip() for p in raw_title.split(":", 1)]
            title = parts[0] or type_name
            superclass = parts[1] if len(parts) > 1 else ""
        elif raw_title:
            title = raw_title

    # Code blocks first (data-code lives on the copy button inside <pre>).
    def code_block(mm: re.Match) -> str:
        pre = mm.group(0)
        dm = re.search(r'data-code="([^"]*)"', pre)
        if dm:
            code = htmllib.unescape(dm.group(1))
        else:
            code = htmllib.unescape(re.sub(r"<[^>]+>", "", pre))
            code = re.sub(r"\n{3,}", "\n\n", code).strip("\n")
        return f"\n```qml\n{code}\n```\n"

    body = re.sub(r"(?s)<pre[^>]*>.*?</pre>", code_block, body)

    # Drop chrome after code extraction.
    body = re.sub(r"(?s)<button[^>]*>.*?</button>", "", body)
    body = re.sub(r"(?s)<svg[^>]*>.*?</svg>", "", body)
    body = re.sub(r"(?s)<script.*?</script>|<style.*?</style>", "", body)
    # Site footer inside the content blob.
    body = re.sub(
        r"(?is)Brought to you by:.*$",
        "",
        body,
    )

    # Property / function cards → bullet lines.
    def prop_card(mm: re.Match) -> str:
        chunk = mm.group(0)
        nm = re.search(
            r'class="[^"]*typeprop-name[^"]*"[^>]*>(.*?)</[^>]+>', chunk, re.S
        )
        name = _text(nm.group(1)) if nm else ""
        if not name:
            return "\n"
        dt_m = re.search(r'class="type-datatype[^"]*"[^>]*>(.*?)</', chunk, re.S)
        dtype = _text(dt_m.group(1)) if dt_m else ""
        det_m = re.search(
            r'class="typedata-detailsdata"[^>]*>(.*?)</div>', chunk, re.S
        )
        details = _text(det_m.group(1)) if det_m else ""
        params = [
            _text(p)
            for p in re.findall(
                r'class="typedata-param[^"]*"[^>]*>(.*?)</', chunk, re.S
            )
        ]
        line = f"**{name}**"
        if dtype:
            line += f" : `{dtype}`"
        if params:
            line += f" ({', '.join(p for p in params if p)})"
        if details:
            line += f" — {details}"
        return f"\n- {line}\n"

    body = re.sub(
        r'(?s)<div class="typedata-root typeprop-root">.*?(?=<div class="typedata-root typeprop-root">|</section>|$)',
        prop_card,
        body,
    )

    body = re.sub(
        r"(?s)<h([1-6])[^>]*>(.*?)</h\1>",
        lambda mm: f"\n{'#' * min(int(mm.group(1)), 3)} {_text(mm.group(2))}\n",
        body,
    )
    # Drop the duplicate big title block (we emit our own header).
    body = re.sub(rf"(?m)^#+\s*{re.escape(title)}\b.*$", "", body, count=1)
    # Keep subheading prose/examples; strip only the wrapper tag.
    body = re.sub(r"</?subheading[^>]*>", "\n", body)
    body = re.sub(r'(?s)<code class="type-module"[^>]*>.*?</code>', "", body)

    body = re.sub(r"(?s)<li[^>]*>(.*?)</li>", lambda mm: f"\n- {_text(mm.group(1))}", body)
    body = re.sub(r"(?s)<p[^>]*>(.*?)</p>", lambda mm: f"\n{_text(mm.group(1))}\n", body)
    body = re.sub(r"(?s)<br\s*/?>", "  \n", body)
    body = re.sub(r"(?s)<hr\s*/?>", "\n", body)
    body = re.sub(r"(?s)<[^>]+>", "", body)
    body = htmllib.unescape(body)

    # Drop leftover TOC name-only bullets (single token, no colon/backtick).
    lines, out = [], []
    for line in body.split("\n"):
        line = re.sub(r"[ \t]+$", "", line)
        stripped = line.strip()
        if re.fullmatch(r"- [A-Za-z_][\w.]*", stripped):
            continue
        if stripped in ("[?]", "Changelog", "GitHub", "Discord"):
            continue
        if stripped.startswith("and our contributors"):
            continue
        if not stripped and out and not out[-1].strip():
            continue
        out.append(line)
    text = "\n".join(out).strip()
    # Remove a second bare "import Module" line after header content.
    text = re.sub(rf"(?m)^import {re.escape(module)}\s*$", "", text).strip()

    header = [f"# {title}", f"`import {module}`"]
    if superclass:
        header.append(f"Extends: `{superclass}`")
    if summary:
        header.extend(["", summary])

    # Drop a leading body paragraph that repeats the summary.
    if summary:
        text = re.sub(
            rf"^\s*{re.escape(summary)}\s*",
            "",
            text,
            count=1,
        ).strip()

    md = "\n".join(header) + ("\n\n" + text if text else "") + "\n"
    md = re.sub(r"\n{3,}", "\n\n", md)
    return md, summary


def load_existing_index(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text())
        return data if isinstance(data, list) else []
    except json.JSONDecodeError:
        return []


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", default=None, help="e.g. 0.3.2 (default: latest mirror)")
    ap.add_argument("--out", default=str(OUT))
    args = ap.parse_args()

    version = args.version or latest_version(MIRROR_ROOT)
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    pages = type_pages(version)
    if not pages:
        raise SystemExit(f"no type pages for v{version}")

    existing = load_existing_index(out_dir / "index.json")
    kept = [r for r in existing if not str(r.get("source", "")).startswith("quickshell-docs")]
    # drop previous QS bodies we're about to rewrite only when name collides with kept? keep all non-QS
    kept_names = {r["type_name"] for r in kept if r.get("type_name")}

    rows = list(kept)
    written = 0
    skipped_collision = 0

    for module, type_name, page in pages:
        # Bare name collision with qch pilot (unlikely for QS): keep qch, skip QS write
        if type_name in kept_names:
            skipped_collision += 1
            continue
        html = page.read_text(encoding="utf-8", errors="replace")
        md, summary = to_markdown(html, type_name, module)
        body_file = f"{type_name}.md"
        # Disambiguate rare duplicate bare names across modules
        dest = out_dir / body_file
        if dest.exists() and any(
            r.get("type_name") == type_name and r.get("source", "").startswith("quickshell-docs")
            for r in rows
        ):
            # second module same name — qualify file
            body_file = f"{module.replace('.', '_')}_{type_name}.md"
            dest = out_dir / body_file

        dest.write_text(md, encoding="utf-8")
        url = f"{CANONICAL_BASE}/v{version}/types/{module}/{type_name}/"
        rows.append(
            {
                "id": f"{module}.{type_name}",
                "type_name": type_name,
                "summary": summary[:200],
                "body_file": body_file,
                "chars": len(md),
                "url": url,
                "source": f"quickshell-docs:v{version}",
            }
        )
        written += 1
        print(f"{module}/{type_name:28} {len(md):6} chars")

    # If two modules exported same bare name, last write wins in index map
    # (qml_docs indexes by type_name). Warn.
    seen: dict[str, str] = {}
    dups = []
    for r in rows:
        tn = r.get("type_name")
        if not tn:
            continue
        if tn in seen and seen[tn] != r.get("id"):
            dups.append(tn)
        seen[tn] = r.get("id", "")
    if dups:
        print(f"warning: duplicate bare names (last wins): {sorted(set(dups))}")

    index_path = out_dir / "index.json"
    index_path.write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")
    print(
        f"\n{written} QS pages, {len(kept)} preserved, "
        f"{skipped_collision} skipped collisions -> {out_dir}"
    )


if __name__ == "__main__":
    main()
