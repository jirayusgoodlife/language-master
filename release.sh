#!/usr/bin/env bash
# ==============================================================================
# Script: release.sh
# Description: Automated Versioning, Build, and GitHub Release for language 0
# Usage:
#   ./release.sh                       # Interactive prompt for version & notes
#   ./release.sh patch "Bug fixes"     # Bump patch: 1.0.0 -> 1.0.1
#   ./release.sh minor "New features"  # Bump minor: 1.0.0 -> 1.1.0
#   ./release.sh major "Major redesign"# Bump major: 1.0.0 -> 2.0.0
#   ./release.sh 1.2.0 "Custom version"# Custom version
# ==============================================================================

set -e

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Ensure we are in the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${CYAN}${BOLD}=============================================${NC}"
echo -e "${CYAN}${BOLD}       language 0 - GitHub Release Tool       ${NC}"
echo -e "${CYAN}${BOLD}=============================================${NC}"

# Check dependencies
command -v git >/dev/null 2>&1 || { echo -e "${RED}Error: git is not installed.${NC}" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}" >&2; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo -e "${RED}Error: flutter is not installed.${NC}" >&2; exit 1; }

# Check GitHub auth status
if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}Error: GitHub CLI (gh) is not authenticated. Run 'gh auth login' first.${NC}" >&2
    exit 1
fi

# Get current version from pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found.${NC}" >&2
    exit 1
fi

CURRENT_VERSION_LINE=$(grep '^version:' pubspec.yaml)
CURRENT_FULL_VERSION=$(echo "$CURRENT_VERSION_LINE" | sed 's/version:[[:space:]]*//')
CURRENT_SEMVER=$(echo "$CURRENT_FULL_VERSION" | cut -d'+' -f1)
CURRENT_BUILD=$(echo "$CURRENT_FULL_VERSION" | cut -d'+' -f2)

if [ -z "$CURRENT_BUILD" ] || [ "$CURRENT_BUILD" = "$CURRENT_SEMVER" ]; then
    CURRENT_BUILD=1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_SEMVER"
MAJOR=${MAJOR:-0}
MINOR=${MINOR:-0}
PATCH=${PATCH:-0}

echo -e "${BLUE}Current Version: ${BOLD}v${CURRENT_SEMVER} (build ${CURRENT_BUILD})${NC}"

# Determine next version
VERSION_ARG="$1"
NOTES_ARG="$2"

if [ -z "$VERSION_ARG" ]; then
    echo -e "\n${YELLOW}Select release type:${NC}"
    echo -e "  1) ${BOLD}patch${NC} (${MAJOR}.${MINOR}.$((PATCH + 1))) - Bug fixes / minor tweaks"
    echo -e "  2) ${BOLD}minor${NC} (${MAJOR}.$((MINOR + 1)).0) - New features"
    echo -e "  3) ${BOLD}major${NC} ($((MAJOR + 1)).0.0) - Breaking changes / major milestone"
    echo -e "  4) ${BOLD}custom${NC} - Specify manual version"
    read -rp "Enter choice [1-4] (default: 1): " CHOICE
    CHOICE=${CHOICE:-1}

    case "$CHOICE" in
        1|patch)
            NEW_SEMVER="${MAJOR}.${MINOR}.$((PATCH + 1))"
            ;;
        2|minor)
            NEW_SEMVER="${MAJOR}.$((MINOR + 1)).0"
            ;;
        3|major)
            NEW_SEMVER="$((MAJOR + 1)).0.0"
            ;;
        4|custom)
            read -rp "Enter new version (e.g. 1.0.2): " MANUAL_VER
            NEW_SEMVER="${MANUAL_VER#v}"
            ;;
        *)
            echo -e "${RED}Invalid choice.${NC}"
            exit 1
            ;;
    esac
else
    case "$VERSION_ARG" in
        patch)
            NEW_SEMVER="${MAJOR}.${MINOR}.$((PATCH + 1))"
            ;;
        minor)
            NEW_SEMVER="${MAJOR}.$((MINOR + 1)).0"
            ;;
        major)
            NEW_SEMVER="$((MAJOR + 1)).0.0"
            ;;
        *)
            NEW_SEMVER="${VERSION_ARG#v}"
            ;;
    esac
fi

NEW_BUILD=$((CURRENT_BUILD + 1))
NEW_FULL_VERSION="${NEW_SEMVER}+${NEW_BUILD}"
TAG_NAME="v${NEW_SEMVER}"

echo -e "\n${GREEN}New Version to Release: ${BOLD}${TAG_NAME} (${NEW_FULL_VERSION})${NC}"

# Release Notes
if [ -z "$NOTES_ARG" ]; then
    echo -e "\n${YELLOW}Enter Release Notes / Changelog (leave empty for default):${NC}"
    read -rp "> " RELEASE_NOTES
    if [ -z "$RELEASE_NOTES" ]; then
        RELEASE_NOTES="Release ${TAG_NAME}: Performance improvements, Japanese & English learning modules, and built-in auto updater."
    fi
else
    RELEASE_NOTES="$NOTES_ARG"
fi

# Confirmation
if [ -t 0 ]; then
    read -rp "Proceed with build & release? [Y/n] " CONFIRM
    CONFIRM=${CONFIRM:-Y}
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Release aborted.${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}Non-interactive terminal detected, proceeding automatically with release...${NC}"
fi

# 1. Update pubspec.yaml
echo -e "\n${BLUE}[1/5] Updating pubspec.yaml to version ${NEW_FULL_VERSION}...${NC}"
sed -i "s/^version:.*/version: ${NEW_FULL_VERSION}/" pubspec.yaml

# 2. Build Release APK
echo -e "\n${BLUE}[2/5] Building Release APK with Flutter...${NC}"
flutter build apk --release

ORIGINAL_APK="build/app/outputs/flutter-apk/app-release.apk"
RELEASE_APK="build/app/outputs/flutter-apk/language-0-${TAG_NAME}.apk"

if [ ! -f "$ORIGINAL_APK" ]; then
    echo -e "${RED}Build failed: $ORIGINAL_APK not found.${NC}" >&2
    exit 1
fi

cp "$ORIGINAL_APK" "$RELEASE_APK"
APK_SIZE=$(du -h "$RELEASE_APK" | cut -f1)
echo -e "${GREEN}✓ APK Built successfully: ${RELEASE_APK} (${APK_SIZE})${NC}"

# 3. Git Commit & Tag
echo -e "\n${BLUE}[3/5] Committing changes & creating tag ${TAG_NAME}...${NC}"
git add pubspec.yaml
if [ -f "pubspec.lock" ]; then
    git add pubspec.lock
fi

# Also stage any uncommitted changes if desired, or commit release version bump
git commit -m "chore(release): bump version to ${TAG_NAME} [skip ci]" || echo "No changes to commit."
git tag -fa "${TAG_NAME}" -m "Release ${TAG_NAME}"

# 4. Push to GitHub
echo -e "\n${BLUE}[4/5] Pushing to GitHub...${NC}"
CURRENT_BRANCH=$(git branch --show-current)
CURRENT_BRANCH=${CURRENT_BRANCH:-main}
git push origin "$CURRENT_BRANCH" --tags

# 5. Create GitHub Release
echo -e "\n${BLUE}[5/5] Creating GitHub Release ${TAG_NAME} and uploading APK...${NC}"
gh release create "${TAG_NAME}" \
    "${RELEASE_APK}#language-0-${TAG_NAME}.apk" \
    --title "language 0 ${TAG_NAME}" \
    --notes "${RELEASE_NOTES}"

RELEASE_URL="https://github.com/jirayusgoodlife/language-master/releases/tag/${TAG_NAME}"
echo -e "\n${GREEN}${BOLD}🎉 Release ${TAG_NAME} Published Successfully!${NC}"
echo -e "${GREEN}Release URL: ${RELEASE_URL}${NC}"
echo -e "${GREEN}Asset: language-0-${TAG_NAME}.apk (${APK_SIZE})${NC}"
