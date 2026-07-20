#!/usr/bin/env python3
"""Generate ``rfc-reference.docx`` — a pandoc ``--reference-doc`` template for RFCs.

The template is tuned so RFC Markdown converts to a Word doc that imports cleanly
into Google Docs:

  * Arial body (11pt) with comfortable line spacing
  * Arial headings, bold, deep blue (#1F4E79), default size hierarchy preserved
    (so the Google Docs outline panel works)
  * left-aligned Title
  * inline ``code`` and fenced code blocks in **Courier New** — a font Google Docs
    is guaranteed to have, so ASCII diagrams stay monospaced/aligned instead of
    falling back to a proportional font
  * a shaded "Source Code" block style
  * tables with thin borders and a bold, shaded header row

Usage::

    python3 build-rfc-reference.py [output.docx]      # defaults to ./rfc-reference.docx

Then convert an RFC with::

    pandoc your-rfc.md -f gfm --reference-doc=rfc-reference.docx -o your-rfc.docx

Requires ``pandoc`` on PATH. Works from pandoc's default reference.docx, so it
depends on the standard pandoc style ids (Heading1..4, Title, VerbatimChar,
Table); if a future pandoc reshuffles those, this script may need a tweak.
"""
import os
import subprocess
import sys
import tempfile
import zipfile
import xml.etree.ElementTree as ET

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
ET.register_namespace("w", W)
ET.register_namespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")

HEADING_COLOR = "1F4E79"   # deep blue for headings + title
HEADER_FILL = "D9E2F3"     # table header shading (light blue)
CODE_FILL = "F2F2F2"       # code shading (light gray)
BORDER_COLOR = "BFBFBF"    # table borders (gray)


def q(tag):
    return f"{{{W}}}{tag}"


def el(tag, attrs=None):
    e = ET.Element(q(tag))
    for k, v in (attrs or {}).items():
        e.set(q(k), v)
    return e


def sub(parent, tag, attrs=None):
    e = el(tag, attrs)
    parent.append(e)
    return e


def make_rpr(font=None, bold=False, italic=False, color=None, sz=None, fill=None):
    """Build a run-properties element with children in schema order."""
    rpr = el("rPr")
    if font:
        rpr.append(el("rFonts", {"ascii": font, "hAnsi": font, "cs": font}))
    if bold:
        rpr.append(el("b"))
        rpr.append(el("bCs"))
    if italic:
        rpr.append(el("i"))
        rpr.append(el("iCs"))
    if color:
        rpr.append(el("color", {"val": color}))
    if sz:
        rpr.append(el("sz", {"val": str(sz)}))
        rpr.append(el("szCs", {"val": str(sz)}))
    if fill:
        rpr.append(el("shd", {"val": "clear", "color": "auto", "fill": fill}))
    return rpr


def customize(styles_xml: bytes) -> bytes:
    root = ET.fromstring(styles_xml)

    def find_style(sid):
        for s in root.findall(q("style")):
            if s.get(q("styleId")) == sid:
                return s
        raise KeyError(f"style {sid!r} not found in reference doc")

    def replace_rpr(st, rpr):
        old = st.find(q("rPr"))
        if old is not None:
            st.remove(old)
        ppr = st.find(q("pPr"))
        if ppr is not None:
            st.insert(list(st).index(ppr) + 1, rpr)
        else:
            st.append(rpr)

    # body defaults: Arial 11pt, comfortable spacing
    docdef = root.find(q("docDefaults"))
    rprd = docdef.find(q("rPrDefault")).find(q("rPr"))
    for rf in rprd.findall(q("rFonts")):
        rprd.remove(rf)
    rprd.insert(0, el("rFonts", {"ascii": "Arial", "hAnsi": "Arial", "cs": "Arial"}))
    for tag in ("sz", "szCs"):
        for e in rprd.findall(q(tag)):
            e.set(q("val"), "22")
    ppd = docdef.find(q("pPrDefault")).find(q("pPr"))
    sp = ppd.find(q("spacing"))
    if sp is None:
        sp = sub(ppd, "spacing")
    sp.set(q("after"), "160")
    sp.set(q("line"), "264")
    sp.set(q("lineRule"), "auto")

    # headings: Arial bold, deep blue, keep default sizes
    for sid, sz in (("Heading1", 40), ("Heading2", 32), ("Heading3", 28), ("Heading4", 24)):
        replace_rpr(find_style(sid), make_rpr(font="Arial", bold=True, color=HEADING_COLOR, sz=sz))

    # Title: left-aligned, Arial bold, deep blue, 26pt
    st = find_style("Title")
    ppr = st.find(q("pPr"))
    jc = ppr.find(q("jc"))
    if jc is None:
        jc = sub(ppr, "jc")
    jc.set(q("val"), "left")
    replace_rpr(st, make_rpr(font="Arial", bold=True, color=HEADING_COLOR, sz=52))

    # inline code -> Courier New with light shade
    replace_rpr(find_style("VerbatimChar"), make_rpr(font="Courier New", sz=20, fill=CODE_FILL))

    # add a Source Code block style (Courier New, shaded)
    sc = el("style", {"type": "paragraph", "customStyle": "1", "styleId": "SourceCode"})
    sub(sc, "name", {"val": "Source Code"})
    sub(sc, "basedOn", {"val": "Normal"})
    scp = sub(sc, "pPr")
    sub(scp, "keepLines")
    sub(scp, "spacing", {"before": "120", "after": "120", "line": "240", "lineRule": "auto"})
    sub(scp, "shd", {"val": "clear", "color": "auto", "fill": CODE_FILL})
    sub(scp, "ind", {"left": "120", "right": "120"})
    scr = sub(sc, "rPr")
    scr.append(el("rFonts", {"ascii": "Courier New", "hAnsi": "Courier New", "cs": "Courier New"}))
    scr.append(el("sz", {"val": "18"}))
    scr.append(el("szCs", {"val": "18"}))
    root.append(sc)

    # table: light borders + bold, shaded header row
    st = find_style("Table")
    tblpr = st.find(q("tblPr"))
    borders = el("tblBorders")
    for side in ("top", "left", "bottom", "right", "insideH", "insideV"):
        borders.append(el(side, {"val": "single", "sz": "4", "space": "0", "color": BORDER_COLOR}))
    cm = tblpr.find(q("tblCellMar"))
    tblpr.insert(list(tblpr).index(cm), borders)
    for tsp in st.findall(q("tblStylePr")):
        if tsp.get(q("type")) == "firstRow":
            rpr = el("rPr")
            rpr.append(el("b"))
            rpr.append(el("bCs"))
            tsp.insert(0, rpr)
            tcpr = tsp.find(q("tcPr"))
            shd = el("shd", {"val": "clear", "color": "auto", "fill": HEADER_FILL})
            val = tcpr.find(q("vAlign"))
            tcpr.insert(list(tcpr).index(val) if val is not None else len(tcpr), shd)

    decl = b'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    return decl + ET.tostring(root, encoding="unicode").encode("utf-8")


def build(out_path: str) -> None:
    with tempfile.TemporaryDirectory() as td:
        base = os.path.join(td, "reference-default.docx")
        with open(base, "wb") as f:
            subprocess.run(
                ["pandoc", "--print-default-data-file", "reference.docx"],
                check=True, stdout=f,
            )
        zin = zipfile.ZipFile(base)
        new_styles = customize(zin.read("word/styles.xml"))
        with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                data = new_styles if item.filename == "word/styles.xml" else zin.read(item.filename)
                zout.writestr(item, data)

    # sanity check the result
    r = ET.fromstring(zipfile.ZipFile(out_path).read("word/styles.xml"))
    title = next(s for s in r.findall(q("style")) if s.get(q("styleId")) == "Title")
    assert title.find(q("pPr")).find(q("jc")).get(q("val")) == "left"
    assert any(s.get(q("styleId")) == "SourceCode" for s in r.findall(q("style")))
    print(f"wrote {out_path}")


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    build(sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "rfc-reference.docx"))
