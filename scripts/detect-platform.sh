#!/usr/bin/env bash
# Detect project platform type for ValidationForge routing
# Usage: ./detect-platform.sh [project-dir]
# Output: ios | react-native | flutter | cli | api | web | fullstack | generic

set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

HAS_IOS=0
HAS_RN=0
HAS_FLUTTER=0
HAS_CLI=0
HAS_API=0
HAS_WEB=0

# iOS detection
if [ -n "$(find . -maxdepth 3 -name '*.xcodeproj' -o -name '*.xcworkspace' -o -name 'Package.swift' 2>/dev/null | head -1)" ]; then
  HAS_IOS=1
fi

# React Native detection
if [ -f package.json ] && grep -q '"react-native"' package.json 2>/dev/null; then
  HAS_RN=1
fi
if [ -f app.json ] && grep -q '"expo"' app.json 2>/dev/null; then
  HAS_RN=1
fi

# Flutter detection
if [ -f pubspec.yaml ] && grep -q '^flutter:' pubspec.yaml 2>/dev/null; then
  HAS_FLUTTER=1
fi

# CLI detection
if [ -f Cargo.toml ] && grep -q '\[\[bin\]\]' Cargo.toml 2>/dev/null; then
  HAS_CLI=1
fi
if [ -f go.mod ] && { [ -f main.go ] || [ -d cmd/ ]; }; then
  HAS_CLI=1
fi
if [ -f pyproject.toml ] && grep -q '\[project.scripts\]' pyproject.toml 2>/dev/null; then
  HAS_CLI=1
fi
if [ -f package.json ] && grep -q '"bin"' package.json 2>/dev/null; then
  HAS_CLI=1
fi

# API detection
API_SIGNALS=$(find . -maxdepth 3 \( -name 'routes*' -o -name 'handlers*' -o -name 'controllers*' -o -name 'swagger*' -o -name 'openapi*' \) 2>/dev/null | head -1)
if [ -n "$API_SIGNALS" ]; then
  HAS_API=1
fi

# Web detection
WEB_SIGNALS=$(find . -maxdepth 3 \( -name '*.jsx' -o -name '*.tsx' -o -name '*.vue' -o -name '*.svelte' -o -name 'next.config*' -o -name 'vite.config*' -o -name 'angular.json' \) 2>/dev/null | head -1)
if [ -n "$WEB_SIGNALS" ]; then
  HAS_WEB=1
fi

# Priority-based output
if [ "$HAS_IOS" -eq 1 ]; then
  echo "ios"
elif [ "$HAS_RN" -eq 1 ]; then
  echo "react-native"
elif [ "$HAS_FLUTTER" -eq 1 ]; then
  echo "flutter"
elif [ "$HAS_CLI" -eq 1 ]; then
  echo "cli"
elif [ "$HAS_WEB" -eq 1 ] && [ "$HAS_API" -eq 1 ]; then
  echo "fullstack"
elif [ "$HAS_API" -eq 1 ]; then
  echo "api"
elif [ "$HAS_WEB" -eq 1 ]; then
  echo "web"
else
  echo "generic"
fi
