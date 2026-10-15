# AI policy

This project is a skill for AI coding agents, and AI coding agents helped build it. This file explains how AI was used
to make it, and what we ask of contributors who use AI tools.

## How this repository was made

- **Direction and decisions: the maintainer.** Gregory Douglas set the goals and the rules, made the design decisions,
  and reviewed the results. He is responsible for everything in this repository, whoever or whatever typed it.
- **Writing: mostly AI, under direction.** Most of the code and prose was drafted by Anthropic's Claude models through
  Claude Code, working from the maintainer's instructions.
- **Research: AI-gathered, then tested.** AI agents surveyed PlantUML's documentation, its issue tracker and common
  practice. Those notes were not taken on trust. Every behaviour the skill relies on was checked by rendering on a
  local PlantUML (1.2026.8 with Graphviz 15.1.1), and only checked results went into `skills/plantuml-diagrams/references/`.
  The raw research notes are not published.
- **Field tests: fresh agents.** The diagrams in `samples/` were built by new agent sessions that followed `SKILL.md`
  literally, so they tested the skill rather than the author's memory of it. Each family's `NOTES.md` is that agent's
  report. Later edits to the infrastructure families replaced real system names with invented ones, moved each
  sample's title style under `document { }` so the SVG and PDF renders keep their borders, and updated one status
  line. The software-design families were built from invented source material and ran twice, before and after their
  round-1 findings were folded back into the skill.
- **Images: rendered, not generated.** Every image in the repository is a PlantUML render of the `.puml` file next to
  it. No AI image generation was used.

## Contributing with AI tools

AI-assisted contributions are welcome under these conditions:

1. **Disclose it.** Name the tool and roughly how much it did in the pull request description, and add a trailer to
   the commits it helped write:

   ```
   Assisted-by: Claude Code (Claude Opus)
   ```

   A `Co-Authored-By:` trailer added by your tool also counts.
2. **Understand it.** You should be able to explain every line you submit without the tool's help.
3. **Run it yourself.** Paste real `tests/run.sh` and `puml-check` output, and look at the renders. A summary such as
   "the agent says the tests pass" is not evidence.
4. **Verify PlantUML claims.** Models are often wrong about PlantUML: they suggest deprecated skinparams, invent theme
   names, and recommend `scale` and `!pragma ratio` for things they cannot do. Any claim about PlantUML's behaviour
   needs a render on a named version.
5. **Edit the prose.** Keep issues and pull request descriptions short, and write or edit them yourself.
6. **Keep private systems private.** Don't paste a real employer's or client's architecture into an issue, a pull
   request, or a sample.

Low-effort, unreviewed AI output may be closed without detailed review.

## Agents working in this repository

[`AGENTS.md`](AGENTS.md) (also linked as `CLAUDE.md`) holds the instructions agents read when they work on this
repository. It is short and also worth a read for human contributors.
