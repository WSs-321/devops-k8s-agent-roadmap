#!/usr/bin/env bash
set -euo pipefail

VERSION=${VERSION:-unreleased}
IMAGE=${IMAGE:-N/A}
DATE=${DATE:-$(date +%F)}

last_tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [ -n "$last_tag" ]; then
  range="$last_tag..HEAD"
else
  range="HEAD"
fi

changes=$(git log "$range" --pretty=format:"- %s (%h)" 2>/dev/null || true)
if [ -z "$changes" ]; then
  changes="- No changes"
fi

cat <<EOF
# Release Note

Version: $VERSION
Date: $DATE
Commit Range: $range
Image: $IMAGE

## Changes

<!-- AUTO_CHANGES_START -->
$changes
<!-- AUTO_CHANGES_END -->

## Risk

-

## Test Evidence

-

## Rollback Plan

-
EOF
