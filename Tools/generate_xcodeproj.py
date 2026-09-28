#!/usr/bin/env python3
"""Generate Ayas.xcodeproj from the files on disk.

Run after adding or removing a source file:

    python3 Tools/generate_xcodeproj.py

Deriving the project from the file tree means the project file can never drift out of
sync with the sources. Object identifiers are hashed from stable keys, so regenerating
produces a byte-identical file and diffs stay readable.
"""
import hashlib
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

APP = "Ayas"
WIDGET = "AyasWidgetExtension"
TESTS = "AyasTests"

DEPLOYMENT_TARGET = "17.0"
SWIFT_VERSION = "5.0"
OBJECT_VERSION = 56

# Bundled as a folder reference: the whole directory is copied, preserving the "Quran"
# subdirectory the library looks in. Adding a translation needs no project change.
QURAN_FOLDER = "Shared/Content/Quran"

SOURCE_DIRS = {
    "shared": "Shared",
    "app": "Ayas",
    "widget": "AyasWidget",
    "tests": "AyasTests",
}

FILE_TYPES = {
    ".swift": "sourcecode.swift",
    ".plist": "text.plist.xml",
    ".entitlements": "text.plist.entitlements",
    ".xcconfig": "text.xcconfig",
    ".md": "net.daringfireball.markdown",
    ".json": "text.json",
    ".png": "image.png",
    ".py": "text.script.python",
}

PRODUCT_TYPES = {
    APP: ("com.apple.product-type.application", "wrapper.application", "Ayas.app"),
    WIDGET: ("com.apple.product-type.app-extension", "wrapper.app-extension", "AyasWidgetExtension.appex"),
    TESTS: ("com.apple.product-type.bundle.unit-test", "wrapper.cfbundle", "AyasTests.xctest"),
}

_ids = {}


def uid(*parts):
    """Stable 24-character identifier derived from a unique key."""
    key = "|".join(parts)
    value = hashlib.md5(key.encode("utf-8")).hexdigest()[:24].upper()
    if _ids.setdefault(value, key) != key:
        raise SystemExit("identifier collision between %r and %r" % (key, _ids[value]))
    return value


# ---------------------------------------------------------------- file discovery

def walk_swift(relative_dir):
    found = []
    base = os.path.join(ROOT, relative_dir)
    for current, directories, files in os.walk(base):
        directories.sort()
        for name in sorted(files):
            if name.endswith(".swift"):
                path = os.path.relpath(os.path.join(current, name), ROOT)
                found.append(path.replace(os.sep, "/"))
    return found


shared_sources = walk_swift(SOURCE_DIRS["shared"])
app_sources = shared_sources + walk_swift(SOURCE_DIRS["app"])
widget_sources = shared_sources + walk_swift(SOURCE_DIRS["widget"])
test_sources = walk_swift(SOURCE_DIRS["tests"])

if not shared_sources or not test_sources:
    raise SystemExit("no sources found — run this from the repository root")

# Everything that should appear in the project navigator.
navigator = sorted(set(
    app_sources + widget_sources + test_sources + [
        "Config/Ayas.xcconfig",
        "Ayas/Info.plist",
        "Ayas/Ayas.entitlements",
        "Ayas/Assets.xcassets",
        "AyasWidget/Info.plist",
        "AyasWidget/AyasWidget.entitlements",
        QURAN_FOLDER,
        "README.md",
    ]
))

for path in navigator:
    if not os.path.exists(os.path.join(ROOT, path)):
        raise SystemExit("missing file referenced by the project: %s" % path)

app_resources = ["Ayas/Assets.xcassets", QURAN_FOLDER]
widget_resources = [QURAN_FOLDER]


def file_type(path):
    if path == QURAN_FOLDER:
        return "folder"
    if path.endswith(".xcassets"):
        return "folder.assetcatalog"
    return FILE_TYPES.get(os.path.splitext(path)[1], "text")


# ---------------------------------------------------------------- object graph

objects = {}

project_id = uid("project")
main_group_id = uid("group", "<root>")
products_group_id = uid("group", "<products>")

file_refs = {path: uid("fileRef", path) for path in navigator}

for path in navigator:
    objects[file_refs[path]] = {
        "isa": "PBXFileReference",
        "lastKnownFileType": file_type(path),
        "path": os.path.basename(path),
        "sourceTree": "<group>",
    }

# Product references live in the Products group, not on disk.
product_refs = {}
for target, (_, wrapper, filename) in PRODUCT_TYPES.items():
    ref = uid("product", target)
    product_refs[target] = ref
    objects[ref] = {
        "isa": "PBXFileReference",
        "explicitFileType": wrapper,
        "includeInIndex": 0,
        "path": filename,
        "sourceTree": "BUILT_PRODUCTS_DIR",
    }

objects[products_group_id] = {
    "isa": "PBXGroup",
    "children": [product_refs[name] for name in (APP, WIDGET, TESTS)],
    "name": "Products",
    "sourceTree": "<group>",
}


def build_groups():
    """Mirror the directory layout in the navigator."""
    tree = {}
    for path in navigator:
        parts = path.split("/")
        node = tree
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node.setdefault("__files__", []).append(path)

    def emit(node, prefix):
        children = []
        for name in sorted(k for k in node if k != "__files__"):
            child_prefix = "%s/%s" % (prefix, name) if prefix else name
            children.append(emit(node[name], child_prefix))
        for path in sorted(node.get("__files__", [])):
            children.append(file_refs[path])

        group_id = uid("group", prefix or "<root-dir>")
        objects[group_id] = {
            "isa": "PBXGroup",
            "children": children,
            "path": os.path.basename(prefix),
            "sourceTree": "<group>",
        }
        return group_id

    roots = []
    for name in sorted(k for k in tree if k != "__files__"):
        roots.append(emit(tree[name], name))
    for path in sorted(tree.get("__files__", [])):
        roots.append(file_refs[path])
    return roots


objects[main_group_id] = {
    "isa": "PBXGroup",
    "children": build_groups() + [products_group_id],
    "sourceTree": "<group>",
}


def build_file(target, path, phase, settings=None):
    identifier = uid("buildFile", target, phase, path)
    entry = {"isa": "PBXBuildFile", "fileRef": file_refs[path]}
    if settings:
        entry["settings"] = settings
    objects[identifier] = entry
    return identifier


def sources_phase(target, paths):
    identifier = uid("phase", target, "sources")
    objects[identifier] = {
        "isa": "PBXSourcesBuildPhase",
        "buildActionMask": 2147483647,
        "files": [build_file(target, path, "sources") for path in paths],
        "runOnlyForDeploymentPostprocessing": 0,
    }
    return identifier


def resources_phase(target, paths):
    identifier = uid("phase", target, "resources")
    objects[identifier] = {
        "isa": "PBXResourcesBuildPhase",
        "buildActionMask": 2147483647,
        "files": [build_file(target, path, "resources") for path in paths],
        "runOnlyForDeploymentPostprocessing": 0,
    }
    return identifier


def frameworks_phase(target):
    identifier = uid("phase", target, "frameworks")
    objects[identifier] = {
        "isa": "PBXFrameworksBuildPhase",
        "buildActionMask": 2147483647,
        "files": [],
        "runOnlyForDeploymentPostprocessing": 0,
    }
    return identifier


def embed_extension_phase():
    """Copies the widget .appex into the app's PlugIns directory (subfolder spec 13)."""
    build_id = uid("buildFile", APP, "embed", WIDGET)
    objects[build_id] = {
        "isa": "PBXBuildFile",
        "fileRef": product_refs[WIDGET],
        "settings": {"ATTRIBUTES": ["RemoveHeadersOnCopy"]},
    }
    identifier = uid("phase", APP, "embed")
    objects[identifier] = {
        "isa": "PBXCopyFilesBuildPhase",
        "buildActionMask": 2147483647,
        "dstPath": "",
        "dstSubfolderSpec": 13,
        "files": [build_id],
        "name": "Embed Foundation Extensions",
        "runOnlyForDeploymentPostprocessing": 0,
    }
    return identifier


def dependency(target_name, on_target_id, label):
    proxy_id = uid("proxy", label)
    objects[proxy_id] = {
        "isa": "PBXContainerItemProxy",
        "containerPortal": project_id,
        "proxyType": 1,
        "remoteGlobalIDString": on_target_id,
        "remoteInfo": target_name,
    }
    identifier = uid("dependency", label)
    objects[identifier] = {
        "isa": "PBXTargetDependency",
        "target": on_target_id,
        "targetProxy": proxy_id,
    }
    return identifier


# ---------------------------------------------------------------- build settings

BASE_DEBUG = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
    "CLANG_WARN_BOOL_CONVERSION": "YES",
    "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
    "CLANG_WARN_UNREACHABLE_CODE": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_TESTABILITY": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "GCC_WARN_UNDECLARED_SELECTOR": "YES",
    "GCC_WARN_UNUSED_FUNCTION": "YES",
    "GCC_WARN_UNUSED_VARIABLE": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "MTL_FAST_MATH": "YES",
    "ONLY_ACTIVE_ARCH": "YES",
    "SDKROOT": "iphoneos",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
    "SWIFT_VERSION": SWIFT_VERSION,
}

BASE_RELEASE = dict(BASE_DEBUG)
BASE_RELEASE.update({
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": "NO",
    "ENABLE_TESTABILITY": "NO",
    "GCC_OPTIMIZATION_LEVEL": "s",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "ONLY_ACTIVE_ARCH": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "SWIFT_OPTIMIZATION_LEVEL": "-O",
    "VALIDATE_PRODUCT": "YES",
})
for key in ("GCC_PREPROCESSOR_DEFINITIONS", "SWIFT_ACTIVE_COMPILATION_CONDITIONS"):
    BASE_RELEASE.pop(key, None)

APP_SETTINGS = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_ENTITLEMENTS": "Ayas/Ayas.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "Ayas/Info.plist",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "PRODUCT_BUNDLE_IDENTIFIER": "$(AYAS_BUNDLE_ID_PREFIX).Ayas",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "1",
}

WIDGET_SETTINGS = {
    "CODE_SIGN_ENTITLEMENTS": "AyasWidget/AyasWidget.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "AyasWidget/Info.plist",
    "LD_RUNPATH_SEARCH_PATHS": [
        "$(inherited)",
        "@executable_path/Frameworks",
        "@executable_path/../../Frameworks",
    ],
    "PRODUCT_BUNDLE_IDENTIFIER": "$(AYAS_BUNDLE_ID_PREFIX).Ayas.widget",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SKIP_INSTALL": "YES",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "1",
}

TEST_SETTINGS = {
    "BUNDLE_LOADER": "$(TEST_HOST)",
    "CODE_SIGN_STYLE": "Automatic",
    "GENERATE_INFOPLIST_FILE": "YES",
    "PRODUCT_BUNDLE_IDENTIFIER": "$(AYAS_BUNDLE_ID_PREFIX).AyasTests",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "TARGETED_DEVICE_FAMILY": "1",
    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Ayas.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Ayas",
}


def configuration_list(label, debug_settings, release_settings, base_config=None):
    entries = []
    for name, settings in (("Debug", debug_settings), ("Release", release_settings)):
        identifier = uid("buildConfig", label, name)
        entry = {"isa": "XCBuildConfiguration", "buildSettings": settings, "name": name}
        if base_config:
            entry["baseConfigurationReference"] = base_config
        objects[identifier] = entry
        entries.append(identifier)

    list_id = uid("configList", label)
    objects[list_id] = {
        "isa": "XCConfigurationList",
        "buildConfigurations": entries,
        "defaultConfigurationIsVisible": 0,
        "defaultConfigurationName": "Release",
    }
    return list_id


xcconfig_ref = file_refs["Config/Ayas.xcconfig"]

project_config = configuration_list("project", BASE_DEBUG, BASE_RELEASE, base_config=xcconfig_ref)


def native_target(name, sources, resources, extra_settings, phases_extra=(), dependencies=()):
    product_type, _, _ = PRODUCT_TYPES[name]
    phases = [sources_phase(name, sources), frameworks_phase(name)]
    phases.append(resources_phase(name, resources))
    phases.extend(phases_extra)

    identifier = uid("target", name)
    objects[identifier] = {
        "isa": "PBXNativeTarget",
        "buildConfigurationList": configuration_list(name, dict(extra_settings), dict(extra_settings)),
        "buildPhases": phases,
        "buildRules": [],
        "dependencies": list(dependencies),
        "name": name,
        "productName": name,
        "productReference": product_refs[name],
        "productType": product_type,
    }
    return identifier


widget_target = native_target(WIDGET, widget_sources, widget_resources, WIDGET_SETTINGS)
app_target = native_target(
    APP,
    app_sources,
    app_resources,
    APP_SETTINGS,
    phases_extra=[embed_extension_phase()],
    dependencies=[dependency(WIDGET, widget_target, "app-needs-widget")],
)
test_target = native_target(
    TESTS,
    test_sources,
    [],
    TEST_SETTINGS,
    dependencies=[dependency(APP, app_target, "tests-need-app")],
)

objects[project_id] = {
    "isa": "PBXProject",
    "attributes": {
        "BuildIndependentTargetsInParallel": 1,
        "LastSwiftUpdateCheck": 1600,
        "LastUpgradeCheck": 1600,
        "TargetAttributes": {
            app_target: {"CreatedOnToolsVersion": "16.0"},
            widget_target: {"CreatedOnToolsVersion": "16.0"},
            test_target: {"CreatedOnToolsVersion": "16.0", "TestTargetID": app_target},
        },
    },
    "buildConfigurationList": project_config,
    "compatibilityVersion": "Xcode 14.0",
    "developmentRegion": "en",
    "hasScannedForEncodings": 0,
    "knownRegions": ["en", "Base"],
    "mainGroup": main_group_id,
    "productRefGroup": products_group_id,
    "projectDirPath": "",
    "projectRoot": "",
    "targets": [app_target, widget_target, test_target],
}

# ---------------------------------------------------------------- serialisation

BARE = re.compile(r"^[A-Za-z0-9_.]+$")


def scalar(value):
    if isinstance(value, int):
        return str(value)
    if BARE.match(value):
        return value
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return '"%s"' % escaped


def serialise(value, depth):
    pad = "\t" * depth
    inner = "\t" * (depth + 1)
    if isinstance(value, dict):
        lines = ["{"]
        for key in sorted(value):
            lines.append("%s%s = %s;" % (inner, scalar(key), serialise(value[key], depth + 1)))
        lines.append("%s}" % pad)
        return "\n".join(lines)
    if isinstance(value, list):
        if not value:
            return "(\n%s)" % pad
        lines = ["("]
        for item in value:
            lines.append("%s%s," % (inner, serialise(item, depth + 1)))
        lines.append("%s)" % pad)
        return "\n".join(lines)
    return scalar(value)


document = {
    "archiveVersion": 1,
    "classes": {},
    "objectVersion": OBJECT_VERSION,
    "objects": objects,
    "rootObject": project_id,
}

text = "// !$*UTF8*$!\n" + serialise(document, 0) + "\n"

project_dir = os.path.join(ROOT, "Ayas.xcodeproj")
os.makedirs(project_dir, exist_ok=True)
with open(os.path.join(project_dir, "project.pbxproj"), "w", encoding="utf-8", newline="\n") as handle:
    handle.write(text)

# A shared scheme so Run and Test work the moment the project is opened.
scheme_dir = os.path.join(project_dir, "xcshareddata", "xcschemes")
os.makedirs(scheme_dir, exist_ok=True)
scheme = """<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app}" BuildableName="Ayas.app" BlueprintName="Ayas" ReferencedContainer="container:Ayas.xcodeproj"></BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{tests}" BuildableName="AyasTests.xctest" BlueprintName="AyasTests" ReferencedContainer="container:Ayas.xcodeproj"></BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app}" BuildableName="Ayas.app" BlueprintName="Ayas" ReferencedContainer="container:Ayas.xcodeproj"></BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app}" BuildableName="Ayas.app" BlueprintName="Ayas" ReferencedContainer="container:Ayas.xcodeproj"></BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration="Debug"></AnalyzeAction>
   <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"></ArchiveAction>
</Scheme>
""".replace("{app}", app_target).replace("{tests}", test_target)

with open(os.path.join(scheme_dir, "Ayas.xcscheme"), "w", encoding="utf-8", newline="\n") as handle:
    handle.write(scheme)

print("Ayas.xcodeproj written")
print("  app    %3d swift files" % len(app_sources))
print("  widget %3d swift files" % len(widget_sources))
print("  tests  %3d swift files" % len(test_sources))
