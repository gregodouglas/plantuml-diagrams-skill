# Contributing

Thanks for helping. This is a small project with one maintainer, so focused issues and small pull requests get handled
fastest.

## Useful contributions

- **A diagram that renders badly after following the skill.** This is the most valuable report: it shows a rule, a
  template or the checker falling short.
- **Checker false positives or misses**: a warning on something that looks fine, or a visible defect it did not report.
- **PlantUML or Graphviz version differences**: behaviour that changed from what `references/` says.
- **Install notes** for a platform or agent harness that isn't covered yet.
- **New templates or reference sections.** Open an issue first, because the skill stays small on purpose.

## Reporting a bug

Include:

1. The `.puml` file, cut down to the smallest version that still shows the problem. Use invented names: never post
   a real employer's or client's architecture.
2. The output of `skills/plantuml-diagrams/scripts/puml-check <file> --target <target> --format json`.
3. A screenshot of the PNG if the problem is visual.
4. `plantuml -version` (the first two lines) and your OS.
5. The agent harness and model, if an agent produced the diagram.

## Development setup

You need PlantUML, Graphviz, Java and Python 3 as listed in the [README](README.md#requirements). There are no other
dependencies.

```sh
plantuml -testdot   # "Installation seems OK"
tests/run.sh        # every line should start with "ok"
```

`tests/run.sh` checks every template against the 16:9 target, runs the fixtures in `tests/fixtures/` against the issue
kinds they must produce, round-trips `puml-new`, validates the `SKILL.md` frontmatter, and checks the renderer's error
exit code.

## Where changes go

| You want to change | Edit | Then |
|---|---|---|
| Agent rules or workflow | `skills/plantuml-diagrams/SKILL.md` | keep it short; detail goes in `references/` |
| The house style or a template | `skills/plantuml-diagrams/scripts/puml-new` (templates are generated from it) | regenerate (below), then `tests/run.sh` |
| A checker rule | `skills/plantuml-diagrams/scripts/puml-check` | add a fixture in `tests/fixtures/` and an `expect` line in `tests/run.sh` |
| Reference material | `skills/plantuml-diagrams/references/*.md` | verify the claim by rendering, and name the PlantUML version |

Regenerate the templates and the include-file style after editing `puml-new`:

```sh
for k in $(skills/plantuml-diagrams/scripts/puml-new list); do
  skills/plantuml-diagrams/scripts/puml-new "$k" "skills/plantuml-diagrams/assets/templates/$k.puml" --title "$k example" --force
done
skills/plantuml-diagrams/scripts/puml-new style > skills/plantuml-diagrams/assets/lib/house.puml
```

## Rules

- **Python standard library only**, compatible with Python 3.6 (RHEL 8's default). No `pip` dependencies.
- **Shell that works on both macOS and Linux**: BSD and GNU tools differ (`sed -i ''`, no `\n` in BSD `sed`
  replacements).
- **Verify before you claim.** Anything new in `references/` or `SKILL.md` about how PlantUML behaves must be
  confirmed by rendering on an installed PlantUML, with the version named. Model knowledge of PlantUML is often out of
  date, and outdated advice is the reason this project exists.
- **Keep the skill portable.** `SKILL.md` frontmatter holds only `name`, `description` and `license`. Use relative
  paths, and nothing that only one harness understands (no `allowed-tools`, no harness environment variables or tools).
  The test suite enforces part of this.
- **Keep it local.** No remote `!include`, no public PlantUML server, no network calls from the scripts.
- **Invented systems only** in samples, fixtures, examples and issues.

Maintainers can keep a `tests/guard.local` file (gitignored, one extended regex per line) of names that must never be
committed; `tests/run.sh` fails if any committed file matches one.

## Pull requests

- One topic per pull request, and say what it changes and why.
- Paste the `tests/run.sh` result and your `plantuml -version`. For layout changes, include before/after renders.
- Write commit subjects in the imperative mood ("Add DFD template", not "Added").
- If an AI tool helped, say so as described in [AI_POLICY.md](AI_POLICY.md).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE), the same as the
project.
