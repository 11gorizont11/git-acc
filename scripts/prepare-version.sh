#!/usr/bin/env bash
set -euo pipefail

# Version injection script for semantic-release
# This script creates a temporary copy of the source, updates the version,
# builds the artifacts, and copies them back to the original dist directory

ver="${1?version required}"
echo "Preparing version ${ver} for build..."

# Store original directory
original_dir="$(pwd)"

# Create temporary directory
tmp_dir="$(mktemp -d)"
echo "Using temporary directory: ${tmp_dir}"

# Copy source to temporary directory
cp -R . "${tmp_dir}"
cd "${tmp_dir}"

# Update version in bin/git-acc
echo "Updating VERSION in bin/git-acc to ${ver}"
if [[ "${OSTYPE}" == "darwin"* ]]; then
    # macOS sed requires empty string for in-place editing
    sed -i "" "s/^VERSION=\".*\"/VERSION=\"${ver}\"/" bin/git-acc
else
    # Linux sed
    sed -i "s/^VERSION=\".*\"/VERSION=\"${ver}\"/" bin/git-acc
fi

# Verify version was updated
if grep -q "VERSION=\"${ver}\"" bin/git-acc; then
    echo "✓ Version successfully updated to ${ver}"
else
    echo "✗ Failed to update version"
    exit 1
fi

# Build the distribution
echo "Building distribution..."
make build

# Create package
echo "Creating package..."
make package

# Generate checksums (portable)
echo "Generating checksums..."
cd dist
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum git-acc > git-acc.sha256
    sha256sum git-acc.tar.gz > git-acc.tar.gz.sha256
else
    shasum -a 256 git-acc > git-acc.sha256
    shasum -a 256 git-acc.tar.gz > git-acc.tar.gz.sha256
fi

# Copy artifacts back to original dist directory
echo "Copying artifacts back to original dist directory..."
# Ensure the dist directory exists in the original location
mkdir -p "${original_dir}/dist"
cp -f git-acc "${original_dir}/dist/"
cp -f git-acc.tar.gz "${original_dir}/dist/"
cp -f git-acc.sha256 "${original_dir}/dist/"
cp -f git-acc.tar.gz.sha256 "${original_dir}/dist/"

# Clean up temporary directory
cd "${original_dir}"
rm -rf "${tmp_dir}"

echo "✓ Version ${ver} preparation completed successfully"
echo "Artifacts ready in dist/ directory:"
ls -la dist/
