#!/usr/bin/env bash
# Link the canonical skill into the directories opencode, Claude Code and the Devin CLI read.
# Idempotent. Run from anywhere.
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/plantuml-diagrams"
NAME="plantuml-diagrams"

link() {
  local dir="$1"; mkdir -p "$dir"
  if [ -e "$dir/$NAME" ] && [ ! -L "$dir/$NAME" ]; then
    echo "skip: $dir/$NAME exists and is not a symlink" >&2; return
  fi
  ln -sfn "$SRC" "$dir/$NAME"; echo "linked $dir/$NAME -> $SRC"
}
link "$HOME/.claude/skills"     # Claude Code + opencode
link "$HOME/.agents/skills"     # Devin CLI + opencode (opencode de-duplicates by name)

echo
echo "toolchain:"
if command -v plantuml >/dev/null; then plantuml -version 2>/dev/null | head -1; plantuml -testdot 2>/dev/null | tail -1
elif [ -n "${PLANTUML_JAR:-}" ]; then "${PLANTUML_JAVA:-java}" -Djava.awt.headless=true -jar "$PLANTUML_JAR" -version 2>/dev/null | head -1
else echo "  plantuml missing: brew install plantuml (macOS) or see docs/INSTALL-RHEL.md (set PLANTUML_JAR)"; fi
if command -v opencode >/dev/null; then
  if opencode debug skill 2>/dev/null | grep -q "\"$NAME\""; then echo "opencode sees $NAME"; else echo "opencode: restart it, then check 'opencode debug skill'"; fi
fi
echo "smoke test:"; "$SRC/scripts/puml-check" "$SRC/assets/templates/sequence.puml" --target 16:9 --out "${TMPDIR:-/tmp}/puml-install-test" | head -2
