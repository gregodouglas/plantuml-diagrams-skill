# Ticketing input: source material for the software-design samples

This folder is **invented source material**, written to look like the docs and code of a small real system. The
`sequence/`, `data-model/`, `state/`, `c4/` and `cloud-aws/` sample families were drawn from it by fresh agents that
followed `skills/plantuml-diagrams/SKILL.md` literally. The skill's rule 12 says to draw only what the code, config or the
user's words establish, so every box and arrow in those samples should trace back to a line in here.

| File | What it stands in for | Diagrams it feeds |
|---|---|---|
| `ARCHITECTURE.md` | the repo's architecture notes: people, external systems, containers | C4 context and container |
| `flows.md` | API and integration flows, step by step | sequence |
| `schema.sql` | the Postgres schema | ER |
| `domain.py` | the domain model, including state machines | class, state |
| `infra.md` | the AWS deployment | cloud / deployment |
