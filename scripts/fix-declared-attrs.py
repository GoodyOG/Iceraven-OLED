#!/usr/bin/env python3
"""Declare res-auto attributes that layouts reference but no values file declares.

Some upstream APKs ship layouts that reference a library attribute whose
declaration was stripped from resources.arsc (seen in IceRaven 2.53.0, whose
Glance widget layouts use `app:glance_isTopLevelLayout`).

Android's inflater ignores unknown attributes at runtime, so the APK works.
aapt2 does not: it fails the link step with
    error: attribute glance_isTopLevelLayout (...) not found
which aborts `apktool b --use-aapt2`.

This scans the decoded tree, finds used-but-undeclared res-auto attributes and
appends plain `<attr name="..."/>` declarations (no format => any value type is
accepted) to res/values/attrs.xml so the rebuild links.
"""
import os
import re
import sys

RES = sys.argv[1] if len(sys.argv) > 1 else "iceraven-patched/res"
VALUES = os.path.join(RES, "values")
ATTRS = os.path.join(VALUES, "attrs.xml")
RES_AUTO = "http://schemas.android.com/apk/res-auto"


def read(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def declared_attrs():
    names = set()
    if not os.path.isdir(VALUES):
        return names
    for fn in os.listdir(VALUES):
        if fn.endswith(".xml"):
            names.update(re.findall(r'<attr\s+name="([^"]+)"', read(os.path.join(VALUES, fn))))
    return names


def used_attrs():
    names = set()
    for dirpath, _, files in os.walk(RES):
        for fn in files:
            if not fn.endswith(".xml"):
                continue
            text = read(os.path.join(dirpath, fn))
            prefixes = set(re.findall(r'xmlns:(\w+)="%s"' % re.escape(RES_AUTO), text))
            if prefixes:
                for pre, name in re.findall(r'(?<![\w:.-])(\w+):([\w.]+)\s*=', text):
                    if pre in prefixes:
                        names.add(name)
            names.update(re.findall(r'\?attr/([A-Za-z_][\w.]*)', text))
    return names


def main():
    declared = declared_attrs()
    missing = sorted(used_attrs() - declared)
    if not missing:
        print("[FIX] all referenced res-auto attributes are declared")
        return 0

    if not os.path.exists(ATTRS):
        os.makedirs(VALUES, exist_ok=True)
        with open(ATTRS, "w", encoding="utf-8") as fh:
            fh.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>\n')

    text = read(ATTRS)
    inject = "".join('    <attr name="%s" />\n' % name for name in missing)
    with open(ATTRS, "w", encoding="utf-8") as fh:
        fh.write(text.replace("</resources>", inject + "</resources>"))

    print("[FIX] declared %d missing attribute(s): %s" % (len(missing), ", ".join(missing)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
