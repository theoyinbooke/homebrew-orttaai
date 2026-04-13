#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/bump-cask.sh --version <version> [--sha256 <sha>]
  ./scripts/bump-cask.sh --version <version> --file </path/to/Orttaai-x.y.z.dmg>
  ./scripts/bump-cask.sh --version <version> --download

Options:
  --version   Required. Release version without the leading "v".
  --sha256    Use an already computed SHA-256.
  --file      Compute SHA-256 from a local DMG file.
  --download  Download the GitHub release DMG and compute SHA-256 automatically.
  --repo      Optional. GitHub repo in owner/name form. Default: theoyinbooke/orttaai
  --help      Show this message.

Examples:
  ./scripts/bump-cask.sh --version 1.0.11 --file ~/Downloads/Orttaai-1.0.11.dmg
  ./scripts/bump-cask.sh --version 1.0.11 --download
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CASK_FILE="${REPO_ROOT}/Casks/orttaai.rb"
APP_REPO="theoyinbooke/orttaai"
VERSION=""
SHA256=""
DMG_FILE=""
DOWNLOAD=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --sha256)
      SHA256="${2:-}"
      shift 2
      ;;
    --file)
      DMG_FILE="${2:-}"
      shift 2
      ;;
    --download)
      DOWNLOAD=true
      shift
      ;;
    --repo)
      APP_REPO="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${VERSION}" ]]; then
  echo "--version is required." >&2
  usage >&2
  exit 1
fi

if [[ -n "${SHA256}" && -n "${DMG_FILE}" ]]; then
  echo "Use only one of --sha256 or --file." >&2
  exit 1
fi

if [[ -n "${SHA256}" && "${DOWNLOAD}" == true ]]; then
  echo "Use only one of --sha256 or --download." >&2
  exit 1
fi

if [[ -n "${DMG_FILE}" && "${DOWNLOAD}" == true ]]; then
  echo "Use only one of --file or --download." >&2
  exit 1
fi

if [[ ! -f "${CASK_FILE}" ]]; then
  echo "Cask file not found: ${CASK_FILE}" >&2
  exit 1
fi

compute_sha_from_file() {
  local file_path="$1"

  if [[ ! -f "${file_path}" ]]; then
    echo "DMG file not found: ${file_path}" >&2
    exit 1
  fi

  shasum -a 256 "${file_path}" | awk '{print $1}'
}

compute_sha_from_download() {
  local version="$1"
  local repo="$2"
  local url="https://github.com/${repo}/releases/download/v${version}/Orttaai-${version}.dmg"
  local temp_dir
  local temp_file

  temp_dir="$(mktemp -d)"
  temp_file="${temp_dir}/Orttaai-${version}.dmg"

  trap 'rm -rf "${temp_dir}"' EXIT

  echo "Downloading ${url}"
  curl -fL --progress-bar -o "${temp_file}" "${url}"
  compute_sha_from_file "${temp_file}"
}

if [[ -z "${SHA256}" ]]; then
  if [[ -n "${DMG_FILE}" ]]; then
    SHA256="$(compute_sha_from_file "${DMG_FILE}")"
  else
    SHA256="$(compute_sha_from_download "${VERSION}" "${APP_REPO}")"
  fi
fi

if [[ ! "${SHA256}" =~ ^[0-9a-fA-F]{64}$ ]]; then
  echo "Computed SHA-256 is invalid: ${SHA256}" >&2
  exit 1
fi

SHA256_LOWER="$(printf '%s' "${SHA256}" | tr '[:upper:]' '[:lower:]')"

perl -0pi -e 's/version "[^"]+"/version "'"${VERSION}"'"/; s/sha256 "[^"]+"/sha256 "'"${SHA256_LOWER}"'"/' "${CASK_FILE}"

echo "Updated ${CASK_FILE}"
echo "  version: ${VERSION}"
echo "  sha256:  ${SHA256_LOWER}"
echo
echo "Next steps:"
echo "  git diff Casks/orttaai.rb"
echo "  git add Casks/orttaai.rb README.md scripts/bump-cask.sh"
echo "  git commit -m \"Bump Orttaai cask to v${VERSION}\""
echo "  git push"
