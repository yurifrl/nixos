#!/usr/bin/env bash
set -euo pipefail

# Bump version, generate AI changelog, commit, and push
# Usage: ./scripts/bump-and-deploy.sh <image> <bump_type>
# Example: ./scripts/bump-and-deploy.sh gatus patch

IMAGE="${1:-gatus}"
BUMP_TYPE="${2:-patch}"
VERSION_FILE="${IMAGE}.version"

# Validate inputs
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "❌ Error: $VERSION_FILE not found"
  exit 1
fi

if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
  echo "❌ Error: Invalid BUMP_TYPE: $BUMP_TYPE (use: major, minor, or patch)"
  exit 1
fi

# Read current version
CURRENT=$(cat "$VERSION_FILE")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# Calculate new version
case "$BUMP_TYPE" in
  major)
    NEW_VERSION="$((MAJOR + 1)).0.0"
    ;;
  minor)
    NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
    ;;
  patch)
    NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
    ;;
esac

echo "✅ Bumping $IMAGE from $CURRENT to $NEW_VERSION"
echo "$NEW_VERSION" > "$VERSION_FILE"

# Generate changelog with AI
echo "🤖 Generating changelog with AI..."

GIT_DIFF=$(git diff HEAD || echo "No changes")
GIT_STATUS=$(git status --short || echo "No status")

CHANGELOG=$(claude --no-color <<EOF
Generate a concise changelog for this NixOS $IMAGE image release.

New version: $NEW_VERSION

Recent changes:
$GIT_STATUS

Diff:
$GIT_DIFF

Format:
- Use conventional commits style
- Be specific about what changed
- 2-3 bullet points maximum
- No markdown formatting
- Start each line with "- "
EOF
)

echo "📝 Changelog:"
echo "$CHANGELOG"

# Stage and commit
git add "$VERSION_FILE"
git add -u

git commit -m "$(cat <<COMMIT_EOF
chore($IMAGE): bump to v$NEW_VERSION

$CHANGELOG
COMMIT_EOF
)"

# Push
echo "🚀 Pushing to GitHub..."
git push

echo ""
echo "✅ Done! GitHub Actions will build and release $IMAGE-v$NEW_VERSION"
echo "🔗 Watch at: https://github.com/yurifrl/nixos/actions"
