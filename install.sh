#!/usr/bin/env bash
# Install every skill in ./skills into Claude Code's personal skills folder.
#
# Claude Code only discovers skills one level deep (<dest>/<name>/SKILL.md), so
# nested skills are flattened:
#   skills/<name>/                         -> <dest>/<name>/
#   skills/skill-superpowers/skills/<n>/   -> <dest>/<n>/
#   skills/superpowers/<category>/         -> <dest>/<category>/   (kept: these skills
#                                             link to ~/.claude/skills/<category>/...)
#   skills/superpowers/<category>/<n>/     -> <dest>/superpowers-classic-<n>/  (discoverable copy,
#                                             frontmatter name rewritten to that slug)
#
# Only the folders listed above are replaced; anything else in <dest> is left alone.
# Usage: ./install.sh [dest]   (default: ~/.claude/skills)   Works in Git Bash, macOS, Linux.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/skills" && pwd)"
DEST="${1:-$HOME/.claude/skills}"
mkdir -p "$DEST"
installed=()

put() { # put <source dir> <dest name>
  rm -rf "${DEST:?}/$2"
  cp -R "$1" "$DEST/$2"
}

# 1. Top-level skills, verbatim.
for d in "$SRC"/*/; do
  name="$(basename "$d")"
  [ "$name" = "superpowers" ] && continue
  [ -f "$d/SKILL.md" ] || continue
  put "$d" "$name"; installed+=("$name")
done

# 2. Current Superpowers sub-skills, promoted to the top level.
for d in "$SRC"/skill-superpowers/skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  name="$(basename "$d")"
  put "$d" "$name"; installed+=("$name")
done

# 3. Classic Superpowers: category tree for internal links, plus discoverable copies.
for cat in "$SRC"/superpowers/*/; do
  c="$(basename "$cat")"
  put "$cat" "$c"
  if [ -f "$cat/SKILL.md" ]; then
    dirs=("$cat")            # e.g. superpowers/using-skills is itself a skill
  else
    dirs=("$cat"*/)
  fi
  for d in "${dirs[@]}"; do
    [ -f "$d/SKILL.md" ] || continue
    name="superpowers-classic-$(basename "$d")"
    put "$d" "$name"
    f="$DEST/$name/SKILL.md"
    # Rewrite only the name: line inside the first frontmatter block.
    awk -v n="$name" '/^---[[:space:]]*$/{fm++} fm==1 && !done && /^name:/{print "name: " n; done=1; next} {print}' \
      "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    installed+=("$name")
  done
done

printf '%s\n' "${installed[@]}" | sort > "$DEST/.claude-skills-installed.txt"
echo "Installed ${#installed[@]} skills into $DEST (list: $DEST/.claude-skills-installed.txt)"
