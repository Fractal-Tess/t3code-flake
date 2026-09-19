#!/usr/bin/env bash
set -euo pipefail

readonly UPSTREAM_REPO="pingdotgg/t3code"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required tool: $1"
}

github_api_get() {
  local url="$1"
  local -a args=(
    --silent
    --show-error
    --fail
    --location
    --header "Accept: application/vnd.github+json"
    --header "X-GitHub-Api-Version: 2022-11-28"
    --header "User-Agent: Fractal-Tess/t3code-flake"
  )

  if [[ -n "${GH_TOKEN:-}" ]]; then
    args+=(--header "Authorization: Bearer ${GH_TOKEN}")
  fi

  curl "${args[@]}" "$url"
}

asset_digest() {
  local release_json="$1"
  local asset_name="$2"
  local digest

  digest="$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .digest' <<<"$release_json")"
  [[ "$digest" == sha256:* ]] || fail "missing SHA-256 digest for ${asset_name}"
  printf '%s\n' "${digest#sha256:}"
}

to_sri() {
  nix hash convert --hash-algo sha256 --to sri "$1"
}

main() {
  local requested_version="${1:-}"
  local current_version release_json version x86_hash arm64_hash

  require_tool curl
  require_tool jq
  require_tool nix
  require_tool sed

  cd "$ROOT_DIR"
  current_version="$(sed -n 's/^  version = "\([^"]*\)";/\1/p' packages/t3code.nix)"
  [[ -n "$current_version" ]] || fail "could not read the packaged version"

  if [[ -n "$requested_version" ]]; then
    version="${requested_version#v}"
    release_json="$(github_api_get "https://api.github.com/repos/${UPSTREAM_REPO}/releases/tags/v${version}")"
  else
    release_json="$(github_api_get "https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest")"
    version="$(jq -r '.tag_name | sub("^v"; "")' <<<"$release_json")"
  fi

  [[ -n "$version" && "$version" != "null" ]] || fail "could not determine the upstream version"
  [[ "$(jq -r '.draft or .prerelease' <<<"$release_json")" == "false" ]] || fail "v${version} is not a stable release"

  printf 'Current version: %s\nLatest version:  %s\n' "$current_version" "$version"
  if [[ "$current_version" == "$version" ]]; then
    printf 'Already up to date.\n'
    exit 0
  fi

  x86_hash="$(to_sri "$(asset_digest "$release_json" "T3-Code-${version}-x86_64.AppImage")")"
  arm64_hash="$(to_sri "$(asset_digest "$release_json" "T3-Code-${version}-arm64.AppImage")")"

  sed -i \
    -e "s|^  version = \"${current_version}\";|  version = \"${version}\";|" \
    -e "/x86_64-linux = {/,/};/ s|^      hash = .*|      hash = \"${x86_hash}\";|" \
    -e "/aarch64-linux = {/,/};/ s|^      hash = .*|      hash = \"${arm64_hash}\";|" \
    packages/t3code.nix

  sed -i \
    -e "s|releases/tag/v${current_version}|releases/tag/v${version}|g" \
    -e "s|T3_Code-${current_version}|T3_Code-${version}|g" \
    -e "s|T3 Code ${current_version}|T3 Code ${version}|g" \
    -e "s|./scripts/update.sh ${current_version}|./scripts/update.sh ${version}|g" \
    README.md

  nix fmt packages/t3code.nix
  nix flake check --print-build-logs
  nix build .#t3code --print-build-logs
  test -x result/bin/t3code || fail "built package does not contain bin/t3code"

  printf 'Updated T3 Code from %s to %s.\n' "$current_version" "$version"
}

main "$@"
