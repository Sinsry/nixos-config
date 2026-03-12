#!/usr/bin/env bash
local=$(nixos-version --json | jq -r '.nixpkgsRevision[:7]')
remote=$(curl -sL --max-time 5 https://channels.nixos.org/nixos-unstable/git-revision | cut -c1-7)

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

echo""
echo -e "${DIM} ────────────────────────${RESET}"
echo -e "${DIM}${RESET}   ${CYAN}NixOS channel status${RESET}  ${DIM}${RESET}"
echo -e "${DIM} ────────────────────────${RESET}"
echo -e "${DIM}${RESET}      local : ${CYAN}${local}${RESET}    ${DIM}${RESET}"
echo -e "${DIM}${RESET}    distant : ${CYAN}${remote}${RESET}    ${DIM}${RESET}"
echo -e "${DIM} ────────────────────────${RESET}"