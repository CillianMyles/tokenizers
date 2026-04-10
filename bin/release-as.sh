#!/usr/bin/env bash

set -e

VERSION=$1

if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$ ]]; then
  echo "Invalid version string: $VERSION"
  exit 1
fi

git commit --allow-empty -m "chore: release $VERSION
Release-As: $VERSION"
