#!/usr/bin/env bash
# Regression tests for the helpers: every template must check clean for its intended target,
# and the fixtures must produce the expected issue kinds. Exit non-zero on any mismatch.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SK="$ROOT/skills/plantuml-diagrams"
OUT="${TMPDIR:-/tmp}/puml-tests"; mkdir -p "$OUT"
fail=0
expect() { # expect <file> <target> <regex that must appear in the issue kinds> <regex that must NOT appear>
  local f="$1" t="$2" must="$3" mustnot="$4"
  local rep; rep=$("$SK/scripts/puml-check" "$f" ${t:+--target "$t"} --format json --out "$OUT" 2>&1)
  local kinds; kinds=$(printf '%s' "$rep" | python3 -c 'import json,sys; r=json.load(sys.stdin); print(" ".join(sorted({i["kind"] for i in r.get("issues",[]) if i.get("level")!="info"}|{l["kind"] for l in r.get("lint",[]) if l.get("level")!="info"}|({"ERROR"} if r.get("status")=="error" else set()))))')
  if [ -n "$must" ] && ! printf '%s' "$kinds" | grep -Eq "$must"; then echo "FAIL $f: expected /$must/ in [$kinds]"; fail=1
  elif [ -n "$mustnot" ] && printf '%s' "$kinds" | grep -Eq "$mustnot"; then echo "FAIL $f: did not expect /$mustnot/ in [$kinds]"; fail=1
  else echo "ok   $(basename "$f") [$kinds]"; fi
}
# templates: slide preset must be clean for 16:9 except the inherently tall activity/usecase ones (aspect only)
for f in "$SK"/assets/templates/*.puml; do
  case "$(basename "$f")" in activity.puml|usecase.puml) expect "$f" 16:9 "" "text-overlap|edge-through|ERROR|banned|lifeline" ;;
                            *) expect "$f" 16:9 "" "." ;; esac
done
# fixtures
expect "$ROOT/tests/fixtures/ortho-labels.puml"     ""   "ortho-with-labels|edge-through-text" ""
expect "$ROOT/tests/fixtures/banner.puml"           ""   "banned-skinparam|deprecated-skinparam-banner" ""
expect "$ROOT/tests/fixtures/long-messages.puml"    16:9 "message-crosses-lifeline|long-edge-label" ""
expect "$ROOT/tests/fixtures/syntax-error.puml"     ""   "ERROR" ""
expect "$ROOT/tests/fixtures/mermaid.puml"          ""   "mermaid-syntax" ""
expect "$ROOT/tests/fixtures/too-wide.puml"         16:9 "aspect" ""
expect "$ROOT/tests/fixtures/group-label.puml"      ""   "group-label-crosses-lifeline" ""
# sequence arrows across intermediate lifelines: frames, dividers, self-messages, notes and activations do not count
got=$("$SK/scripts/puml-check" "$ROOT/tests/fixtures/lifeline-spans.puml" --format json --out "$OUT" | python3 -c 'import json,sys; r=json.load(sys.stdin); i=[x["detail"] for x in r["issues"] if x["kind"]=="message-spans-lifelines"]; print(r["edge_crossings"], r["lifeline_crossings"], i[0].split(" (")[0] if i else "-")')
want="None 7 4 of 9 messages cross the lifelines between their participants"
if [ "$got" = "$want" ]; then echo "ok   sequence lifeline crossings"; else echo "FAIL sequence lifeline crossings: got '$got', want '$want'"; fail=1; fi
expect "$ROOT/tests/fixtures/group-label-centred.puml" "" "group-label-crosses-lifeline" ""
expect "$ROOT/tests/fixtures/message-centred.puml" ""  "message-crosses-lifeline" ""
expect "$ROOT/tests/fixtures/bracket-label.puml"    ""   "bracket-group-label" ""
# edges that share a node and leave it on one trunk: the field-test samples that showed it (a cut-down graph does not reproduce it)
expect "$ROOT/samples/cloud-aws/medium.puml"       16:9 "bundled-edges" ""
expect "$ROOT/samples/data-model/class-small.puml" ""   "bundled-edges" ""
expect "$ROOT/samples/data-model/class-small.puml" ""   "crowded-ends" ""
# sequence text issues carry the source line (the SVG gives none for them)
ln=$("$SK/scripts/puml-check" "$ROOT/tests/fixtures/group-label.puml" --format gcc --out "$OUT" | sed -n 's/.*group-label\.puml:\([0-9]*\): warn: group-label-crosses-lifeline.*/\1/p')
if [ "$ln" = "9" ]; then echo "ok   sequence issue line"; else echo "FAIL sequence issue line: got '$ln', want 9"; fail=1; fi
# line numbers must point into the user's file even when !include <C4/...> expands to ~1800 lines
f="$ROOT/tests/fixtures/c4-include-lines.puml"; n=$(wc -l < "$f")
bad=$("$SK/scripts/puml-check" "$f" --format json --out "$OUT" | python3 -c 'import json,sys; r=json.load(sys.stdin); n=int(sys.argv[1]); src=open(sys.argv[2]).read().splitlines(); print(" ".join("%s:%s" % (i["kind"], i["line"]) for i in r["issues"] if i.get("line") and (i["line"] > n or ("label" in i["kind"] and i["detail"].split("\x27")[1] not in src[i["line"]-1]))))' "$n" "$f")
if [ -n "$bad" ]; then echo "FAIL include line mapping: $bad"; fail=1; else echo "ok   include line mapping (C4)"; fi
# state diagrams: the SVG groups only described states, so counts come from the source
cnt=$("$SK/scripts/puml-check" "$SK/assets/templates/state.puml" --format json --out "$OUT" | python3 -c 'import json,sys; c=json.load(sys.stdin)["counts"]; print(c["nodes"], c["edges"])')
if [ "$cnt" = "6 6" ]; then echo "ok   state counts"; else echo "FAIL state counts: $cnt (want 6 6)"; fail=1; fi
# a failed render must name any older render of the same file as stale
touch -t 202001010000 "$OUT/syntax-error.svg"
rep=$("$SK/scripts/puml-check" "$ROOT/tests/fixtures/syntax-error.puml" --format json --out "$OUT")   # exits 2 by design
if printf '%s' "$rep" | grep -q '"stale"'; then echo "ok   stale render flagged"; else echo "FAIL stale render not flagged"; fail=1; fi
# scaffolder round-trip
for k in $("$SK/scripts/puml-new" list); do "$SK/scripts/puml-new" "$k" "$OUT/new-$k.puml" --force >/dev/null || { echo "FAIL puml-new $k"; fail=1; }; done
# portability guard: nothing harness-specific inside the skill folder
GUARD='CLAUDE_|allowed-tools|\.claude/'
if /usr/bin/grep -rniE "$GUARD" "$SK" >/dev/null; then
  echo "FAIL portability guard: harness-specific names in $SK:"; /usr/bin/grep -rniE "$GUARD" "$SK" | head; fail=1
else echo "ok   portability guard (nothing harness-specific in skills/)"; fi
# leak guard: private names (tests/guard.local, gitignored, one ERE per line) in any file that would be committed
LOCAL_GUARD="$ROOT/tests/guard.local"
if [ -f "$LOCAL_GUARD" ]; then
  pat=$(/usr/bin/grep -vE '^[[:space:]]*(#|$)' "$LOCAL_GUARD" | paste -s -d '|' -)
  # outside a repository, a throwaway git dir over the work tree gives the same .gitignore-aware file list
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then gitls() { git -C "$ROOT" ls-files -z -co --exclude-standard; }
  else GD="$OUT/guard-git"; rm -rf "$GD"; git init -q --bare "$GD"
       gitls() { git --git-dir="$GD" --work-tree="$ROOT" ls-files -z -co --exclude-standard; }; fi
  hits=$(cd "$ROOT" && gitls | xargs -0 /usr/bin/grep -nIiE "$pat" 2>/dev/null)
  if [ -n "$hits" ]; then echo "FAIL leak guard: private names found:"; printf '%s\n' "$hits" | cut -c1-200 | head -20; fail=1
  else echo "ok   leak guard ($(/usr/bin/grep -cvE '^[[:space:]]*(#|$)' "$LOCAL_GUARD") private patterns, no hits)"; fi
else echo "skip leak guard (no tests/guard.local)"; fi
# frontmatter: name matches folder, only name/description/license
fm=$(sed -n '2,/^---$/p' "$SK/SKILL.md" | sed '$d')
if printf '%s' "$fm" | /usr/bin/grep -qE '^name: plantuml-diagrams$' && ! printf '%s' "$fm" | /usr/bin/grep -qE '^(metadata|compatibility|allowed-tools|context|paths):'; then echo "ok   frontmatter"; else echo "FAIL frontmatter: $fm"; fail=1; fi
# renderer error contract
if "$SK/scripts/puml-render" "$ROOT/tests/fixtures/syntax-error.puml" --out "$OUT" >/dev/null 2>&1; then echo "FAIL puml-render should exit 2 on error"; fail=1; else echo "ok   puml-render error exit"; fi
exit $fail
