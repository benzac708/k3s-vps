#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
case "$(uname -m)" in
  x86_64) ARCH=amd64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

ACTIONLINT_VERSION=1.7.12
KUBECONFORM_VERSION=0.8.0
GITLEAKS_VERSION=8.30.1
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

case "$ARCH" in
  amd64)
    ACTIONLINT_SHA=8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8
    KUBECONFORM_SHA=9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883
    GITLEAKS_ARCHIVE="gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
    GITLEAKS_SHA=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb
    ;;
  arm64)
    ACTIONLINT_SHA=325e971b6ba9bfa504672e29be93c24981eeb1c07576d730e9f7c8805afff0c6
    KUBECONFORM_SHA=1f53fc8e81258197a35e8603054162a5af1de8c5af13746c71ab680d9534ed87
    GITLEAKS_ARCHIVE="gitleaks_${GITLEAKS_VERSION}_linux_arm64.tar.gz"
    GITLEAKS_SHA=e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080
    ;;
esac

mkdir -p "$INSTALL_DIR"

ACTIONLINT_ARCHIVE="actionlint_${ACTIONLINT_VERSION}_linux_${ARCH}.tar.gz"
KUBECONFORM_ARCHIVE="kubeconform-linux-${ARCH}.tar.gz"
curl --fail --location --silent --show-error \
  "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/${ACTIONLINT_ARCHIVE}" \
  --output "$TMP_DIR/$ACTIONLINT_ARCHIVE"
printf '%s  %s\n' "$ACTIONLINT_SHA" "$TMP_DIR/$ACTIONLINT_ARCHIVE" | sha256sum --check --status
tar -xzf "$TMP_DIR/$ACTIONLINT_ARCHIVE" -C "$TMP_DIR" actionlint
install -m 0755 "$TMP_DIR/actionlint" "$INSTALL_DIR/actionlint"

curl --fail --location --silent --show-error \
  "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/${KUBECONFORM_ARCHIVE}" \
  --output "$TMP_DIR/$KUBECONFORM_ARCHIVE"
printf '%s  %s\n' "$KUBECONFORM_SHA" "$TMP_DIR/$KUBECONFORM_ARCHIVE" | sha256sum --check --status
tar -xzf "$TMP_DIR/$KUBECONFORM_ARCHIVE" -C "$TMP_DIR" kubeconform
install -m 0755 "$TMP_DIR/kubeconform" "$INSTALL_DIR/kubeconform"

curl --fail --location --silent --show-error \
  "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/${GITLEAKS_ARCHIVE}" \
  --output "$TMP_DIR/$GITLEAKS_ARCHIVE"
printf '%s  %s\n' "$GITLEAKS_SHA" "$TMP_DIR/$GITLEAKS_ARCHIVE" | sha256sum --check --status
tar -xzf "$TMP_DIR/$GITLEAKS_ARCHIVE" -C "$TMP_DIR" gitleaks
install -m 0755 "$TMP_DIR/gitleaks" "$INSTALL_DIR/gitleaks"

"$INSTALL_DIR/actionlint" -version
"$INSTALL_DIR/kubeconform" -v
"$INSTALL_DIR/gitleaks" version
