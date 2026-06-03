#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_path="${project_root}/.build/keyboard-event-probe"

mkdir -p "${project_root}/.build"
swiftc \
  "${project_root}/Tools/KeyboardEventProbe.swift" \
  -o "${output_path}"

exec "${output_path}" "$@"
