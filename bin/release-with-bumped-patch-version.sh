#!/usr/bin/env bash

set -e

CURRENT_VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')
echo "Current version: $CURRENT_VERSION"

MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3 | cut -d+ -f1)

BUMPED_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
echo "Bumped version: $BUMPED_VERSION"

./bin/release-as.sh "$BUMPED_VERSION"
