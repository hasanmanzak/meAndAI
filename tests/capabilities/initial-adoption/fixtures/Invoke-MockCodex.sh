#!/usr/bin/env bash
set -euo pipefail

arguments=("$@")
last_index=$((${#arguments[@]} - 1))
if (( last_index >= 0 )) && [[ "${arguments[$last_index]}" == "-" ]]; then
  unset 'arguments[$last_index]'
fi

fixture_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec pwsh -NoProfile -File "$fixture_directory/Invoke-MockCodex.ps1" "${arguments[@]}"
