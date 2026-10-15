# Working in this repo

This repo IS the skill. The canonical content is `skills/plantuml-diagrams/`; everything else supports it.

- Edit `scripts/puml-new` to change the house style or a template, then regenerate: `for k in $(skills/plantuml-diagrams/scripts/puml-new list); do skills/plantuml-diagrams/scripts/puml-new $k skills/plantuml-diagrams/assets/templates/$k.puml --title "$k example" --force; done` and `skills/plantuml-diagrams/scripts/puml-new style > skills/plantuml-diagrams/assets/lib/house.puml`.
- Run `tests/run.sh` before committing. Every template must check clean for 16:9 (activity and use case may carry an `aspect` warning only).
- Claims in `references/` must be verified on the installed PlantUML (`plantuml -version`); note the version when behaviour changes.
- Scripts are stdlib Python 3 only; no pip dependencies. macOS BSD tools (no GNU sed `\n`).
- Nothing private goes in a committed file: no employer, client or internal system names, hostnames or home paths. Samples use invented, generic systems. `tests/guard.local` (gitignored, one regex per line) lists the private names; `tests/run.sh` fails if any committed file matches.
- Commits you help write carry an `Assisted-by:` (or `Co-Authored-By:`) trailer naming the tool, per `AI_POLICY.md`. Human-facing docs: `README.md`, `CONTRIBUTING.md`, `AI_POLICY.md`, `SECURITY.md`, `CHANGELOG.md` (add an entry under Unreleased for user-visible changes).
