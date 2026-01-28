#!/usr/bin/env python3
"""
Add CloudKitPlugin.swift and CloudKitService.swift to Xcode project.

This script modifies ios/Runner.xcodeproj/project.pbxproj to include:
- CloudKitPlugin.swift
- CloudKitService.swift

It generates unique IDs for PBXFileReference and PBXBuildFile entries,
adds the files to the appropriate group, and adds them to the Sources build phase.
"""

import re
import secrets
import sys
from pathlib import Path


def generate_xcode_id() -> str:
    """Generate a unique 24-character hexadecimal ID for Xcode."""
    return secrets.token_hex(12).upper()


def read_pbxproj(project_path: Path) -> str:
    """Read the pbxproj file."""
    pbxproj_path = project_path / "project.pbxproj"
    if not pbxproj_path.exists():
        raise FileNotFoundError(f"project.pbxproj not found at {pbxproj_path}")
    return pbxproj_path.read_text()


def write_pbxproj(project_path: Path, content: str):
    """Write the modified pbxproj file."""
    pbxproj_path = project_path / "project.pbxproj"
    pbxproj_path.write_text(content)


def add_pbx_file_references(content: str, file_ids: dict) -> str:
    """
    Add PBXFileReference entries for CloudKit Swift files.

    Args:
        content: The pbxproj file content
        file_ids: Dictionary with 'plugin' and 'service' keys containing IDs

    Returns:
        Modified content with new PBXFileReference entries
    """
    # Find the end of the PBXFileReference section
    # We want to add before the "/* End PBXFileReference section */" line

    plugin_entry = f"\t\t{file_ids['plugin']} /* CloudKitPlugin.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CloudKitPlugin.swift; sourceTree = \"<group>\"; }};\n"
    service_entry = f"\t\t{file_ids['service']} /* CloudKitService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CloudKitService.swift; sourceTree = \"<group>\"; }};\n"

    # Insert before the "/* End PBXFileReference section */" line
    pattern = r"(/\* End PBXFileReference section \*/)"
    replacement = f"{plugin_entry}{service_entry}\\1"

    return re.sub(pattern, replacement, content)


def add_pbx_build_files(content: str, build_ids: dict, file_ids: dict) -> str:
    """
    Add PBXBuildFile entries for CloudKit Swift files.

    Args:
        content: The pbxproj file content
        build_ids: Dictionary with 'plugin' and 'service' keys containing build file IDs
        file_ids: Dictionary with 'plugin' and 'service' keys containing file reference IDs

    Returns:
        Modified content with new PBXBuildFile entries
    """
    plugin_entry = f"\t\t{build_ids['plugin']} /* CloudKitPlugin.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ids['plugin']} /* CloudKitPlugin.swift */; }};\n"
    service_entry = f"\t\t{build_ids['service']} /* CloudKitService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ids['service']} /* CloudKitService.swift */; }};\n"

    # Insert before the "/* End PBXBuildFile section */" line
    pattern = r"(/\* End PBXBuildFile section \*/)"
    replacement = f"{plugin_entry}{service_entry}\\1"

    return re.sub(pattern, replacement, content)


def add_to_runner_group(content: str, file_ids: dict) -> str:
    """
    Add CloudKit Swift files to the Runner group.

    The Runner group's children list needs to include the new file references.

    Args:
        content: The pbxproj file content
        file_ids: Dictionary with 'plugin' and 'service' keys containing file reference IDs

    Returns:
        Modified content with files added to Runner group
    """
    plugin_ref = f"\t\t\t\t{file_ids['plugin']} /* CloudKitPlugin.swift */,\n"
    service_ref = f"\t\t\t\t{file_ids['service']} /* CloudKitService.swift */,\n"

    # The Runner group ends with the bridging header reference followed by closing
    # We need to insert our files before the closing ); of the children array
    # Pattern: \t\t\t\t74858FAD1ED2DC5600515810 /* Runner-Bridging-Header.h */,\n\t\t\t);

    runner_group_pattern = r"(74858FAD1ED2DC5600515810 /\* Runner-Bridging-Header\.h \*/,\n)(\t\t\t\);)"

    def runner_group_replacer(match):
        header_line = match.group(1)
        closing = match.group(2)
        return f"{header_line}{plugin_ref}{service_ref}{closing}"

    result = re.sub(runner_group_pattern, runner_group_replacer, content)

    # If pattern didn't match (maybe file order changed), try alternative approach
    if result == content:
        # Look for any line ending with ); after children in Runner group
        # Match the last child reference before closing
        alt_pattern = r"(\t\t\t\t[A-F0-9]{24} /\* [^*]+ \*/,\n)(\t\t\t\);\n\t\t\tpath = Runner;\n\t\t\tsourceTree = \"<group>\";)"
        result = re.sub(alt_pattern, lambda m: m.group(1) + plugin_ref + service_ref + m.group(2), result)

    return result


def add_to_sources_build_phase(content: str, build_ids: dict) -> str:
    """
    Add CloudKit Swift files to the Sources build phase.

    Args:
        content: The pbxproj file content
        build_ids: Dictionary with 'plugin' and 'service' keys containing build file IDs

    Returns:
        Modified content with build files added to Sources phase
    """
    # The Sources build phase for Runner is: 97C146EA1CF9000F007C117D
    # We need to add the build file references to the files array

    plugin_ref = f"\t\t\t\t{build_ids['plugin']} /* CloudKitPlugin.swift in Sources */,\n"
    service_ref = f"\t\t\t\t{build_ids['service']} /* CloudKitService.swift in Sources */,\n"

    # Find the Sources build phase for Runner and add files to it
    # Pattern: 97C146EA1CF9000F007C117D /* Sources */ = { ... files = ( ... ); ... };

    sources_phase_pattern = r"(97C146EA1CF9000F007C117D /\* Sources \*/ = \{\s*isa = PBXSourcesBuildPhase;\s*buildActionMask = 2147483647;\s*files = \(\s*[^)]*?)(\t\t\);)"

    def sources_replacer(match):
        files_content = match.group(1)
        closing = match.group(2)
        return f"{files_content}{plugin_ref}{service_ref}{closing}"

    return re.sub(sources_phase_pattern, sources_replacer, content, flags=re.DOTALL)


def modify_pbxproj(project_path: Path) -> bool:
    """
    Modify the pbxproj file to include CloudKit Swift files.

    Args:
        project_path: Path to the Xcode project directory

    Returns:
        True if successful, False otherwise
    """
    content = read_pbxproj(project_path)

    # Generate unique IDs
    file_ids = {
        'plugin': generate_xcode_id(),
        'service': generate_xcode_id(),
    }
    build_ids = {
        'plugin': generate_xcode_id(),
        'service': generate_xcode_id(),
    }

    print(f"Generated PBXFileReference IDs:")
    print(f"  CloudKitPlugin.swift: {file_ids['plugin']}")
    print(f"  CloudKitService.swift: {file_ids['service']}")
    print(f"Generated PBXBuildFile IDs:")
    print(f"  CloudKitPlugin.swift: {build_ids['plugin']}")
    print(f"  CloudKitService.swift: {build_ids['service']}")

    # Modify the content in order
    content = add_pbx_build_files(content, build_ids, file_ids)
    print("Added PBXBuildFile entries")

    content = add_pbx_file_references(content, file_ids)
    print("Added PBXFileReference entries")

    content = add_to_runner_group(content, file_ids)
    print("Added files to Runner group")

    content = add_to_sources_build_phase(content, build_ids)
    print("Added files to Sources build phase")

    # Write the modified content
    write_pbxproj(project_path, content)
    print(f"Updated {project_path / 'project.pbxproj'}")

    return True


def verify_files_exist(project_root: Path) -> bool:
    """
    Verify that the Swift files exist.

    Args:
        project_root: Root path of the project

    Returns:
        True if both files exist, False otherwise
    """
    plugin_path = project_root / "ios" / "Runner" / "CloudKitPlugin.swift"
    service_path = project_root / "ios" / "Runner" / "CloudKitService.swift"

    if not plugin_path.exists():
        print(f"Error: {plugin_path} does not exist")
        return False
    if not service_path.exists():
        print(f"Error: {service_path} does not exist")
        return False

    print(f"Verified: {plugin_path}")
    print(f"Verified: {service_path}")
    return True


def main():
    """Main entry point."""
    # Get the project root directory (assuming script is in scripts/ at project root)
    script_path = Path(__file__).resolve()
    project_root = script_path.parent.parent

    # Verify Swift files exist
    if not verify_files_exist(project_root):
        sys.exit(1)

    # Path to Xcode project
    xcode_project = project_root / "ios" / "Runner.xcodeproj"

    if not xcode_project.exists():
        print(f"Error: Xcode project not found at {xcode_project}")
        sys.exit(1)

    print(f"Modifying Xcode project at: {xcode_project}")
    print()

    # Modify the pbxproj file
    try:
        if modify_pbxproj(xcode_project):
            print()
            print("Successfully added CloudKit files to Xcode project!")
            print()
            print("Next steps:")
            print("  1. Open ios/Runner.xcodeproj in Xcode")
            print("  2. Verify CloudKitPlugin.swift and CloudKitService.swift appear in the Runner group")
            print("  3. Build the project to ensure everything compiles")
        else:
            print("Error: Failed to modify pbxproj file")
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
