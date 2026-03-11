#!/usr/bin/env bash
local=$(nixos-version --json | jq -r '.nixpkgsRevision[:7]')
remote=$(curl -sL --max-time 5 https://channels.nixos.org/nixos-unstable/git-revision | cut -c1-7)

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

if [ "$local" = "$remote" ]; then
  echo -e "$local ${GREEN}✓${RESET}"
else
  echo -e "$local → $remote ${RED}✗${RESET}"
fi
