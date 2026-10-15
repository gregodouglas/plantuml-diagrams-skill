# Sample suite: twelve diagram families

Built by fresh agents following `skills/plantuml-diagrams/SKILL.md` literally, as a field test of the skill. Every system shown is
invented and generic. Most families have `small`, `medium`, `large` (overview) plus `large-*` detail splits, renders in
`out/`, and a `NOTES.md` with a results table, what the skill lacked for that domain, checker false positives/misses, and
the layout tricks that worked.

The five software-design families (`sequence/` to `cloud-aws/`) were drawn from [`ticketing-input/`](ticketing-input/):
invented architecture notes, flows, schema, domain code and AWS deployment for one ticketing system. The agents were told
to draw only what that material establishes, so you can check each diagram against its source.

| Family | What it covers | Notes |
|---|---|---|
| `sequence/` | sign-in (OIDC + PKCE), checkout with three payment outcomes, webhook idempotency, purchase-to-door story split by flow | `alt` branches, splitting by flow vs `newpage`, slide size limits |
| `data-model/` | ER at three sizes (full 16-table schema split by subject area) and class diagrams of the domain model | cardinalities from foreign keys, stub entities, rows of tables |
| `state/` | ticket, order, payment and refund lifecycles, plus how the machines trigger each other | every transition drawn once, direction for lifecycles |
| `c4/` | system context, containers (sales and async paths), API components, full container view for print | C4 stdlib, boundary titles, slide vs print on one content |
| `cloud-aws/` | AWS request path (plain and with bundled AWS icons), VPC across two AZs, full deployment split by layer | offline `awslib` includes, nesting limits, primary/standby pairs |
| `network-boundary/` | perimeter: ISP, HA firewalls, DMZ, zones, cloud, remote users | zone colours, HA pairs, overview+detail with stub nodes |
| `network-intranet/` | VLANs, switch fabric, wireless, servers, inter-VLAN policy; one `nwdiag` alternative | split by layer; nwdiag limits |
| `vmware/` | vSphere clusters, vDS, SAN fabric A/B, arrays, DR replication | A/B idioms, folding chains, anchor scatter |
| `kubernetes/` | ingress, namespaces, workloads, storage, platform services; icon variants | sprite scale/colour, namespace nesting |
| `cicd/` | web app + API pipeline (GitHub Actions to Kubernetes): activity per stage + component overview | gates pattern, fork bars, repeat labels |
| `cicd-toolchain/` | self-hosted CI/CD platform: two views of one pipeline (C4 / component toolchain, activity run) | muted legacy node, accent/alert classes, loop edge moved to legend |
| `dataflow/` | DFD level 0/1 for a courier platform, with trust boundaries and PII flows | boundary title crossings, write-only flows |

The software-design families ran twice: round 1's findings were folded into the skill (`references/state.md`,
`data-model.md`, `c4.md`, the AWS recipe, the `c4-component` template and checker fixes), then fresh agents rebuilt the
families from scratch. Their `NOTES.md` files are the round-2 reports, and section (f) of each says what the revisions
fixed and what they did not.

Everything the infrastructure families' notes taught was folded back into the skill (`references/domains.md`, templates `network` and `dfd`, the
house-style stroke fix, new checker rules). The sample files themselves still carry each agent's own workarounds from before
those fixes; re-scaffolding with the current `puml-new` is the clean path. The one later edit: every sample's title style
sits under `document { }`, so the SVG and PDF renders keep their borders (the stroke bug in `references/style.md`).
