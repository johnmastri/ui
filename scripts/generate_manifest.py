#!/usr/bin/env python3
import json
import hashlib
import os
import sys
from datetime import datetime
from pathlib import Path

def calculate_sha256(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256_hash.update(chunk)
    return sha256_hash.hexdigest()

def get_file_size(file_path):
    return os.path.getsize(file_path)

def load_version():
    version_file = Path('../version.json')
    if not version_file.exists():
        print(f"Error: version.json not found at {version_file}")
        sys.exit(1)
    
    with open(version_file, 'r') as f:
        return json.load(f)

def load_changelog():
    changelog_file = Path('../CHANGELOG.md')
    if not changelog_file.exists():
        return "No changelog available"
    
    with open(changelog_file, 'r') as f:
        lines = f.readlines()
        
        # Find the latest version section
        changelog_lines = []
        in_latest = False
        for line in lines:
            if line.startswith('## '):
                if in_latest:
                    break
                in_latest = True
                continue
            if in_latest and line.strip():
                changelog_lines.append(line.strip())
        
        return '\n'.join(changelog_lines[:5])  # First 5 lines

def generate_manifest(version_info, github_repo, output_dir):
    version = version_info['ui']  # Assuming all components have same version
    
    manifest = {
        "latest_version": version,
        "release_date": datetime.utcnow().isoformat() + 'Z',
        "components": {},
        "minimum_versions": {
            "ui": "1.0.0",
            "server": "1.0.0",
            "firmware": "1.0.0"
        },
        "update_notes": load_changelog(),
        "requires_restart": True,
        "critical": False
    }
    
    # Process each component
    components = {
        'ui': f'ui-v{version}.zip',
        'server': f'server-v{version}.zip',
        'firmware': f'firmware-v{version}.bin'
    }
    
    for component, filename in components.items():
        file_path = Path(output_dir) / filename
        
        if not file_path.exists():
            print(f"Warning: {filename} not found, skipping...")
            continue
        
        print(f"Processing {component}: {filename}")
        
        sha256 = calculate_sha256(file_path)
        size = get_file_size(file_path)
        
        manifest['components'][component] = {
            "version": version,
            "url": f"https://github.com/{github_repo}/releases/download/v{version}/{filename}",
            "sha256": sha256,
            "size_bytes": size,
            "changelog": f"{component.capitalize()} updated to v{version}"
        }
        
        print(f"  SHA256: {sha256}")
        print(f"  Size: {size} bytes")
    
    # Write manifest
    manifest_path = Path(output_dir) / 'manifest.json'
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    print(f"\nManifest generated: {manifest_path}")
    return manifest

def main():
    if len(sys.argv) < 3:
        print("Usage: generate_manifest.py <github_repo> <output_dir>")
        print("Example: generate_manifest.py user/controller_v2 ./release")
        sys.exit(1)
    
    github_repo = sys.argv[1]
    output_dir = sys.argv[2]
    
    print("=" * 60)
    print("MastrCtrl Manifest Generator")
    print("=" * 60)
    print(f"GitHub Repo: {github_repo}")
    print(f"Output Dir: {output_dir}")
    print("")
    
    version_info = load_version()
    print(f"Version: {version_info['ui']}")
    print("")
    
    manifest = generate_manifest(version_info, github_repo, output_dir)
    
    print("")
    print("=" * 60)
    print("Manifest Generation Complete!")
    print("=" * 60)
    
    return 0

if __name__ == '__main__':
    sys.exit(main())

