# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `puml-check` reports `message-spans-lifelines` (info) for sequence diagrams: how many messages are drawn across the
  lifelines between their two participants, naming the worst pairs. The summary line prints
  `crossings=n/a lifeline-crossings=N` for sequence diagrams instead of `crossings=0`, and the JSON `edge_crossings`
  is `null` for them.

### Changed

- The check-and-fix loop no longer stops at a fixed 3 rounds. Counting `warn` lines from the first run that renders,
  it keeps going while a run sets a new low, and stops after two runs that do not, or at 12 runs.
  `references/choosing-and-design.md` now lists simplify and split moves for each diagram type.

### Fixed

- `puml-check` now reports a message or `alt`/`else`/`loop` label that is crossed by a lifeline running through its
  middle. Before, any text centred on a lifeline was skipped as if it were a participant name.

## [0.1.0] - 2026-10-14

First public release.

### Added

- `plantuml-diagrams` Agent Skill for PlantUML: 14 hard rules and an 8-step render-and-check workflow in `SKILL.md`, with
  reference files for layout, labels, sequence, activity, state, ER and class, C4, style, toolchain, failure modes,
  diagram choice and domain recipes (network, CI/CD, DFD, VMware, Kubernetes, AWS with offline icons).
- `puml-new`: 13 tested templates (sequence, activity, component, deployment, class, state, use case, ER, network, DFD,
  C4 context, C4 container, C4 component) with the house style inlined, plus the style as an include file.
- `puml-check`: source lint (including bracketed `alt`/`else` labels, which PlantUML reads as links), render and SVG
  geometry checks (text overlap, edge through text, lifeline crossings,
  alt/else/loop labels crossed by lifelines, labels on borders, aspect ratio against the usable slot, tiny text,
  missing strokes, PNG cropping, banner-painting skinparams) with text, JSON and gcc output. Issues carry the line in
  your file even when the diagram includes C4 or another library, and a failed render names stale images left in
  `--out`.
- `puml-render`: slide, print and web export presets with a reliable error contract.
- `install.sh` for Claude Code, Codex CLI, opencode, Devin CLI and the Deep Agents CLI; permission snippets for
  Claude Code and opencode; RHEL install notes.
- A before/after worked example, a README sequence diagram drawn with the skill, and twelve field-test sample families
  with notes: seven infrastructure families, and five software-design families (sequence, ER and class, state, C4,
  AWS) drawn from invented source material in `samples/ticketing-input/`.
- Regression tests: templates, fixtures, scaffolder round-trip, include line mapping, state counts, stale renders,
  frontmatter, portability and private-name guards.

[Unreleased]: https://github.com/gregodouglas/plantuml-diagrams-skill/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/gregodouglas/plantuml-diagrams-skill/releases/tag/v0.1.0
