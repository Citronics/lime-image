#!/bin/bash
set -e

ARCH="arm"
CROSS_COMPILE="arm-linux-gnueabihf-"
CONFIG_LOCALVERSION="-citronics-lime"

ROOT_DIR=$(pwd)

TAG=$(git describe --tags --exact-match 2>/dev/null) || TAG=""
if [ -n "$TAG" ]; then
  PKG_VERSION=${TAG#v}
else
  PKG_VERSION=$(git describe --tags --always 2>/dev/null || echo "0.0")
  echo "WARNING: No exact git tag on current commit. Using version: $PKG_VERSION" >&2
  echo "         For releases, tag first: git tag v2.0" >&2
fi

CONFIGS_DIR="$ROOT_DIR/configs"
SOURCES_DIR="$ROOT_DIR/sources"
OUTPUT_BASE="$ROOT_DIR/output"
BUILD_BASE="$ROOT_DIR/build"
KERNELS_CONF="$ROOT_DIR/kernels.conf"

if [ ! -f "$KERNELS_CONF" ]; then
  echo "ERROR: kernels.conf not found" >&2
  exit 1
fi

# Allow building a single kernel: ./build-all-kernels.sh msm8x74-6.15.y
FILTER="${1:-}"

mkdir -p "$SOURCES_DIR"

while IFS= read -r line; do
  # Skip comments and empty lines
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// /}" ]] && continue

  NAME=$(echo "$line" | awk '{print $1}')
  REPO_URL=$(echo "$line" | awk '{print $2}')
  BRANCH=$(echo "$line" | awk '{print $3}')

  # If filter is set, skip non-matching kernels
  if [ -n "$FILTER" ] && [ "$NAME" != "$FILTER" ]; then
    continue
  fi

  CONFIG_FILE="${CONFIGS_DIR}/${NAME}.config"
  SOURCE_DIR="${SOURCES_DIR}/${NAME}"
  OUTPUT_DIR="${OUTPUT_BASE}/${NAME}"
  BUILD_DIR="${BUILD_BASE}/${NAME}"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE" >&2
    exit 1
  fi

  echo "🔁 Building kernel: $NAME"
  echo "   Repo:   $REPO_URL (branch: $BRANCH)"
  echo "   Config: $CONFIG_FILE"

  # Clone or fetch the kernel source
  if [ -d "$SOURCE_DIR/.git" ]; then
    echo "   Fetching updates..."
    git -C "$SOURCE_DIR" fetch origin "$BRANCH"
  else
    echo "   Cloning..."
    rm -rf "$SOURCE_DIR"
    git clone --single-branch --branch "$BRANCH" "$REPO_URL" "$SOURCE_DIR"
  fi

  # Clean up any previous build dir
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"

  # Copy source to build dir (avoid polluting the cached clone)
  git -C "$SOURCE_DIR" checkout "origin/$BRANCH" -- .
  cp -a "$SOURCE_DIR/." "$BUILD_DIR/"

  cd "$BUILD_DIR"

  # Setup build environment
  export ARCH="$ARCH"
  export CROSS_COMPILE="$CROSS_COMPILE"
  export DEBEMAIL="info@citronics.eu"
  export DEBFULLNAME="Citronics"

  # Copy config and build
  cp "$CONFIG_FILE" .config
  make olddefconfig

  echo "🚧 Building kernel .deb packages for $NAME"
  make -j$(nproc) \
       LOCALVERSION=$CONFIG_LOCALVERSION \
       KDEB_PKGVERSION=$PKG_VERSION \
       deb-pkg

  # Move packages to output
  mkdir -p "$OUTPUT_DIR"
  cd "$BUILD_DIR/.."
  mv ./*.deb "$OUTPUT_DIR/" 2>/dev/null || true

  # Also check build dir parent for debs (different kernel versions place them differently)
  cd "$BUILD_DIR"
  mv ../*.deb "$OUTPUT_DIR/" 2>/dev/null || true

  rm -f "$OUTPUT_DIR"/*-dbg_*.deb "$OUTPUT_DIR"/linux-libc-dev_*.deb

  echo "✅ Done: $OUTPUT_DIR"
  cd "$ROOT_DIR"
done < "$KERNELS_CONF"

echo ""
echo "🎉 All builds completed successfully."
echo "Output:"
ls -la "$OUTPUT_BASE"/*/
