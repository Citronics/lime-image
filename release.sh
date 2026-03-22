#!/bin/bash
set -e

TAG=$(git describe --tags --exact-match)
VERSION=${TAG#v}

echo "Building lime kernel packages $VERSION..."
./build-all-kernels.sh "$@"

DEBS=$(find output/ \( -name "linux-image-*.deb" -o -name "linux-headers-*.deb" \) | grep -v dbg)
if [ -z "$DEBS" ]; then
  echo "ERROR: No .deb files found in output/"
  exit 1
fi

echo "Packages to release:"
echo "$DEBS"
echo ""

echo "Creating GitHub release $TAG..."
# shellcheck disable=SC2086
gh release create "$TAG" $DEBS \
  --repo Citronics/lime-image \
  --title "lime-image $VERSION" \
  --notes "Kernel image and headers for Citronics Lime $VERSION"

echo "Done. Release $TAG published."
