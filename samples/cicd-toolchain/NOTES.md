# Self-hosted CI/CD platform samples: notes

Skill under test: `skills/plantuml-diagrams` (current), PlantUML 1.2026.8. All files scaffolded with `skills/plantuml-diagrams/scripts/puml-new`
(`c4-container`, `component`, `activity`), checked with `skills/plantuml-diagrams/scripts/puml-check --target 16:9 --png`, exported with
`skills/plantuml-diagrams/scripts/puml-render --preset slide`. Every PNG was opened and looked at. The tools are a generic, plausible
self-hosted stack; swap in your own.

Two views of one pipeline, because one picture cannot answer both questions:

| File | Question it answers | Type | Best slot |
|---|---|---|---|
| `toolchain.puml` | Which systems exist and what talks to what? | C4 container | 16:9 slide |
| `toolchain-component.puml` | Same question, plain UML, no C4 chrome or stdlib include | component | 16:9 slide |
| `pipeline-run.puml` | What happens, in what order, when a developer pushes? | activity with swimlanes | roughly square; narrow on a letter page |

## Results

| File | Type | Target | Size WxH | Ratio | Status | Rounds |
|---|---|---|---|---|---|---|
| toolchain.puml | C4 container | 16:9 | 1584x850 | 1.86 | OK | 1 + 0 (added a caption after the PNG pass) |
| toolchain-component.puml | component | 16:9 | 1206x681 | 1.77 | OK | 2 + 0 |
| pipeline-run.puml | activity | 16:9 | 1035x1051 | 0.98 | WARN `aspect` only (too tall; expected for swimlanes) | 1 + 0 |

Round log:
- **toolchain**: r1 left-to-right C4 came out OK at once. The PNG showed that C4's auto-legend knows nothing about the
  accent / alert / muted tags, so a `caption` carries that meaning.
- **toolchain-component**: r1 had `edge-through-text` (the Vault edge crossed the "Build network" title, because it targeted a
  member) and `edge-through-own-label` (the same-rank "trigger" edge). r2 linked Vault to the package (`vault --> build`) and
  dropped the label on the same-rank edge: OK.
- **pipeline-run**: activity diagrams cannot go left-to-right, so the aspect warning is accepted. The gate fork keeps it compact.

## What each system does (plain language)

- **Forgejo**: holds the code (repos, pull requests), defines the pipeline (workflow files) and stores built container images (registry).
- **Actions runners (Build network)**: the machines that execute pipeline jobs. Forgejo hands them jobs; they run builds, scans and deployments.
- **Legacy build server**: drawn grey because it is optional and being retired. When no jobs remain, delete the box.
- **SSO (OIDC)**: the identity provider. People sign in once to the forge, SonarQube and the Kubernetes API. The one blue box, because everything depends on it.
- **Vault**: the secrets store. Runners fetch short-lived credentials at job start instead of keeping secrets in repo variables. Red because it is the sensitive one.
- **Semgrep, SonarQube, Grype**: the gates. Semgrep (security) and SonarQube (quality) read source; Grype reads the built image for known CVEs. A failed gate stops the run and reports on the pull request.
- **Terraform**: infrastructure as code: creates and changes the VMs, networks and load balancers the cluster runs on (`plan`, then `apply`).
- **Ansible**: configuration and deployment: configures the nodes and runs the deploy playbooks. Sits beside Terraform in the Delivery row.
- **Kubernetes cluster**: where the workloads end up; it pulls images from the registry.

## What the skill lacked

1. **C4 tags are invisible in the legend.** `$tags="accent"` styles the box (the house classes work), but `SHOW_LEGEND()` lists only person / container / boundary. Add a `caption` explaining colour.
2. **An edge that loops around the whole diagram** (cluster pulls images from the registry) wrecks the layout. It is omitted from the picture and stated in the legend or caption instead. SKILL.md has no rule for this.
3. **Link to the package, not the member**, when the flow targets a group (Vault to "Build network"): the member edge cut through the package title.

## Layout tricks that worked

- **Stages as columns** under `left to right direction`: identity and secrets | forge | build | gates | delivery | cluster.
- **Columns via hidden links**: `b -[hidden]right- a` gives a column (same rank, written bottom-to-top); `a -[hidden]- b` would make a row.
- **Delivery row**: Terraform and Ansible in one package, both pointing at the cluster.
- **Gates as a fork, happy path in the then-branch**; the failure exit is the else with `stop`, so there is no long bypass edge.
- **Same-rank `->` only on unlabelled edges** (Repos to Workflows); a label on it gets struck by its own edge.
- **Accent / alert / muted** used once each: SSO, Vault, legacy server.

## How to extend without breaking the layout

- Add systems as members of an existing row (package) rather than new rows; new rows make the diagram taller.
- Keep edge labels to 1-3 words; put protocol detail in a note.
- Link to a package (`runner --> gates`) when the flow goes to the group; link to a member only when it matters.
- Keep new edges in the flow direction (left to right); describe loop-back edges in the legend instead of drawing them.
- Re-run `skills/plantuml-diagrams/scripts/puml-check <file> --target 16:9 --png --out samples/cicd-toolchain/out`; fix what it reports, one change at a time, then look at the PNG.
