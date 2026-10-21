#!/usr/bin/env python3
"""Check that Ayas.xcodeproj is internally consistent and matches the files on disk.

    python3 Tools/verify_project.py

Exits non-zero on any problem. Run after generate_xcodeproj.py, and in CI before
spending a macOS runner minute on a build that would fail for a missing file.

Checks performed:
  - the project file parses as an OpenStep plist
  - every object reference resolves to an object that exists
  - every file reference resolves to a path that exists on disk
  - no target compiles the same file twice, or compiles a non-Swift file
  - each target has Debug and Release configurations
  - the project's build configurations are backed by Config/Ayas.xcconfig
  - the app embeds the widget extension into PlugIns (dstSubfolderSpec 13)
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(ROOT, "Ayas.xcodeproj", "project.pbxproj")

EXPECTED_TARGETS = {"Ayas", "AyasWidgetExtension", "AyasTests"}


class Parser:
    """Minimal OpenStep plist reader — enough for the subset Xcode writes."""

    def __init__(self, text):
        if text.startswith("// !$*UTF8*$!"):
            text = text.split("\n", 1)[1]
        self.text = text
        self.pos = 0

    def skip_ws(self):
        while self.pos < len(self.text) and self.text[self.pos] in " \t\n\r":
            self.pos += 1

    def parse(self):
        self.skip_ws()
        char = self.text[self.pos]
        if char == "{":
            return self.parse_dict()
        if char == "(":
            return self.parse_list()
        if char == '"':
            return self.parse_quoted()
        return self.parse_bare()

    def parse_dict(self):
        self.pos += 1
        result = {}
        while True:
            self.skip_ws()
            if self.text[self.pos] == "}":
                self.pos += 1
                return result
            key = self.parse()
            self.skip_ws()
            assert self.text[self.pos] == "=", "expected = at %d" % self.pos
            self.pos += 1
            result[key] = self.parse()
            self.skip_ws()
            assert self.text[self.pos] == ";", "expected ; after %s" % key
            self.pos += 1

    def parse_list(self):
        self.pos += 1
        result = []
        while True:
            self.skip_ws()
            if self.text[self.pos] == ")":
                self.pos += 1
                return result
            result.append(self.parse())
            self.skip_ws()
            if self.text[self.pos] == ",":
                self.pos += 1

    def parse_quoted(self):
        self.pos += 1
        out = []
        while self.text[self.pos] != '"':
            if self.text[self.pos] == "\\":
                self.pos += 1
            out.append(self.text[self.pos])
            self.pos += 1
        self.pos += 1
        return "".join(out)

    def parse_bare(self):
        start = self.pos
        while self.text[self.pos] not in " \t\n\r=;,(){}":
            self.pos += 1
        return self.text[start:self.pos]


def main():
    if not os.path.exists(PATH):
        print("project file missing — run Tools/generate_xcodeproj.py")
        return 1

    with open(PATH, encoding="utf-8") as handle:
        parser = Parser(handle.read())
    document = parser.parse()
    parser.skip_ws()
    if parser.pos < len(parser.text):
        print("trailing content at offset %d" % parser.pos)
        return 1

    objects = document["objects"]
    errors = []
    uuid = re.compile(r"^[0-9A-F]{24}$")

    for oid, obj in objects.items():
        if not uuid.match(oid):
            errors.append("malformed object id %s" % oid)
        if "isa" not in obj:
            errors.append("object %s has no isa" % oid)
            continue
        for key, value in obj.items():
            if key == "remoteGlobalIDString":
                continue
            for item in (value if isinstance(value, list) else [value]):
                if isinstance(item, str) and uuid.match(item) and item not in objects:
                    errors.append("dangling reference %s from %s.%s" % (item, obj["isa"], key))

    root = objects[document["rootObject"]]
    if root["isa"] != "PBXProject":
        errors.append("rootObject is %s, expected PBXProject" % root["isa"])

    # Resolve file references through the group tree.
    resolved = {}

    def walk(group_id, prefix):
        for child in objects[group_id]["children"]:
            node = objects[child]
            if node["isa"] == "PBXGroup":
                walk(child, os.path.join(prefix, node.get("path", "")))
            elif node["isa"] == "PBXFileReference" and node.get("sourceTree") == "<group>":
                resolved[child] = os.path.normpath(os.path.join(prefix, node["path"]))

    walk(root["mainGroup"], "")

    for ref, relative in resolved.items():
        if not os.path.exists(os.path.join(ROOT, relative)):
            errors.append("file reference does not exist on disk: %s" % relative)

    targets = [objects[t] for t in root["targets"]]
    names = {t["name"] for t in targets}
    if names != EXPECTED_TARGETS:
        errors.append("targets are %s, expected %s" % (sorted(names), sorted(EXPECTED_TARGETS)))

    rows = []
    for target in targets:
        phases = [objects[p] for p in target["buildPhases"]]
        sources = next((p for p in phases if p["isa"] == "PBXSourcesBuildPhase"), None)
        if sources is None:
            errors.append("%s has no sources phase" % target["name"])
            continue

        paths = [resolved.get(objects[b]["fileRef"], "?") for b in sources["files"]]
        if len(paths) != len(set(paths)):
            errors.append("%s compiles a file more than once" % target["name"])
        if not all(p.endswith(".swift") for p in paths):
            errors.append("%s has a non-Swift file in its sources phase" % target["name"])

        configs = objects[target["buildConfigurationList"]]["buildConfigurations"]
        config_names = sorted(objects[c]["name"] for c in configs)
        if config_names != ["Debug", "Release"]:
            errors.append("%s configurations are %s" % (target["name"], config_names))

        rows.append((target["name"], target["productType"].rsplit(".", 1)[-1], len(paths)))

    for cid in objects[root["buildConfigurationList"]]["buildConfigurations"]:
        config = objects[cid]
        base = config.get("baseConfigurationReference")
        if not base:
            errors.append("project %s configuration has no xcconfig" % config["name"])
        elif resolved.get(base, "").replace("\\", "/") != "Config/Ayas.xcconfig":
            errors.append("project xcconfig resolves to %r" % resolved.get(base))

    app = next((t for t in targets if t["name"] == "Ayas"), None)
    if app:
        embeds = [objects[p] for p in app["buildPhases"] if objects[p]["isa"] == "PBXCopyFilesBuildPhase"]
        if not embeds:
            errors.append("the app has no phase embedding the widget extension")
        elif str(embeds[0]["dstSubfolderSpec"]) != "13":
            errors.append("embed phase uses subfolder %s, expected 13 (PlugIns)" % embeds[0]["dstSubfolderSpec"])

    print("objects:            %d" % len(objects))
    print("file references:    %d" % len(resolved))
    for name, kind, count in sorted(rows):
        print("  %-22s %-14s %2d sources" % (name, kind, count))

    if errors:
        print("\nFAILED")
        for error in errors:
            print("  - %s" % error)
        return 1

    print("\nOK: project is internally consistent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
