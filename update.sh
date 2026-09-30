#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if (( $# > 1 )); then
  echo "usage: $0 [VERSION]" >&2
  exit 2
fi
args=()
if (( $# )); then
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Expected a stable x.y.z version' >&2; exit 2; }
  args=("--version=$1")
fi
nix-update --flake "${args[@]}" px0
