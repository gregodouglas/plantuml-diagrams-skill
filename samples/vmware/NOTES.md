# VMware vSphere + SAN samples: test notes

Skill under test: `skills/plantuml-diagrams` (SKILL.md v0.1.0), PlantUML 1.2026.8, Graphviz OK (`plantuml -testdot`).
All files scaffolded with `scripts/puml-new deployment`, checked with `scripts/puml-check`, exported with `scripts/puml-render`
(`--preset slide` for small/medium, `--preset print` for large*). Every final PNG was opened and looked at.

**The skill changed while I was working.** SKILL.md, `references/{layout,failure-modes,toolchain}.md` and `puml-new` have mtime
19:14 (about when I started) and `puml-check` changed again at 19:33, midway through. The numbers below come from the final re-run on
the 19:33 checker. Where an earlier checker version behaved differently, I say so.

## (a) Results

Rounds = checker rounds (max 3) + vision rounds after the PNG pass (max 2). Final sizes are SVG px at 1x.

| File | Target | Size WxH | Ratio | Final status / remaining issues | Rounds |
|---|---|---|---|---|---|
| small.puml | 16:9 | 772x497 | 1.55 | OK | 3 + 2 |
| medium.puml | 16:9 | 1400x806 | 1.74 | OK. Visually, VM groups sits as a loose 2x2 with empty space, and the "2x 25G LAN" label hugs the cluster border | 3 + 2 |
| large.puml (overview, 12 nodes) | letter-landscape | 1065x726 | 1.47 | OK. Visually, the "to DR site" edge loops to the package corner and there is empty space top-right | 3 + 2 |
| large-compute.puml (17 nodes) | letter-landscape | 816x693 | 1.18 | OK. Visually, the vmnic0/vmnic1 edges cross in an X that the checker does not count (see c) | 3 + 2 |
| large-storage.puml (10 nodes) | letter-landscape | 848x630 | 1.35 | OK, 1 crossing (inherent to an A/B mesh) | 3 + 2 (the 2nd vision round was reverted) |
| large-dr.puml (9 nodes) | letter-landscape | 800x568 | 1.41 | OK | 2 + 2 (the 2nd vision round was reverted) |

Round log (what each round changed and what it produced):
- **small**: r1 LR gave 1506x308 (ratio 4.89, aspect). r2 TB gave 431x869 (0.50, aspect, plus edge-through-text). r3 LR with three
  same-rank `->` edges gave 799x497 OK, **but the PNG showed all three labels struck through by their own vertical edges**
  (the checker of that time was silent). v1 moved those labels into node names. v2 was the house-style title fix (see b1).
- **medium**: r1 1430x1166 (1.23): in LR, unlinked members of a package stack in one tall column. r2 grid-wrap hidden links: 1.28.
  r3 restructured into role columns (mgmt/VMs | vDS | hosts | switches | array): OK at 1.37. v1 hidden rows for hosts and datastores:
  1.82. v2 dropped the VM-group hidden links: 1.71.
- **large**: r1 LR 3.05, aspect plus tiny-text. r2 TB 0.56. r3 TB with same-rank WAN edges: OK at 1.50, **but the WAN-to-DR edges ran
  back through the whole HQ package**, which the checker reported only as `info`. v1 `-right->` hints changed nothing.
  v2 one edge from WAN to the DR package instead of three: 1.44.
- **large-compute**: r1 0.89 (aspect, edge-through-text 'MLAG', detached-label). r2 hidden alignment: 1.28, but text-overlap and
  edge-through-text. r3 ToR A/B as a "ToR pair (MLAG)" package instead of a labelled peer-link edge: 1.76 aspect. v1 2x2 host grid
  and reversed stack operands: OK at 1.19. v2 reordered the edges so ToR A sits above ToR B.
- **large-storage**: r1 LR 2.14. r2 TB 0.50 with 2 edge-through-text. r3 LR with the LUNs stacked in one column: OK at 1.40.
  v1 legend glyphs. v2 a 2x2 LUN grid went back to 2.13, so I reverted it.
- **large-dr**: r1 1.81 aspect. r2 made the HQ backup edge same-rank: OK at 1.36, but the PNG showed 'nightly backup' struck by its
  own edge. v1 moved the label into the repo name. v2 a row of DR hosts gave 2.01, so I reverted it.

**Why large is split.** The full two-site estate is about 36 nodes: 2 vCenters, 6 HQ hosts and 2 DR hosts, 4 port groups,
4 VM groups, 2 ToR, 2 FC switches, 2 storage controllers, 8 LUNs/arrays, Veeam B&R, proxy and 2 repos, WAN. That is far over the
20-node hard cap in SKILL rule 6. So `large.puml` is a 12-node overview where each subsystem is one box ("FC fabric A / B",
"Cluster PROD 4 hosts"), plus three detail diagrams, one per question:
- **compute/network**: how do hosts reach the LAN redundantly?
- **storage**: how many independent paths per LUN?
- **DR**: what leaves HQ, and how?

Each detail diagram is 9-17 nodes and repeats only the overview box it expands. The vCenters are left out of the DR detail on
purpose: it is about data flows.

## (b) What was unclear, missing or wrong for this domain

1. **Bug in the house style (the biggest finding).** The top-level `title { ...; LineThickness 0 }` in the inlined style leaks into
   node, component, database, storage, actor and usecase shapes, so they get **no stroke in the SVG or PDF**. The PNG is
   unaffected, because Java2D draws a 0-width stroke as a hairline.
   - Proof: `grep -oE '<(polygon|rect|path)[^>]*>' out.svg | grep -vc stroke` drops from 22 to 0 on the stock `component` template
     once the rule is wrapped as `document { title { ... } }`. The deployment, usecase and c4-container templates are affected the
     same way; class, state and sequence are not.
   - `title { LineColor white }` leaks as well (the nodes get a `stroke:#FFF`).
   - `references/style.md` actually recommends "Use `LineThickness 0` to hide a border", which is exactly the trigger.
   - Neither the checker (it measures geometry) nor the vision pass (it reads the PNG) can see this. The rasterised PDF showed nodes
     with only their 3D edge lines and databases with no outline at all.
   - I patched the style line in every sample (each file has a comment pointing here). Recommended fix in the skill: generate
     `document { title { FontSize ..; FontStyle bold; LineThickness 0 } }`, and add a checker rule that counts SVG shapes with no
     stroke.
2. **Redundant A/B paths: no guidance.** The skill has nothing on HA pairs. Three idioms worked, one per zoom level:
   - Overview: put "A / B" in the node name ("FC fabric\nA / B") and keep a single edge.
   - Compute: a borderless pair package ("ToR pair (MLAG)") instead of a labelled peer-link edge. A labelled same-rank edge between
     the two switches struck its own label and other edges' labels.
   - Storage: two separate switch nodes, with fabric A edges as solid `#0072B2` and fabric B edges as dashed `#E69F00`, plus a
     legend. That removed every per-path label.
   The colour/dash edge syntax (`-[#0072B2]->`, `-[#E69F00,dashed]->`) is not in the skill (see e).
3. **Choosing node, package, rectangle, cloud, database or storage.** The deployment template shows each keyword once, with no
   guidance on what to use for infrastructure. What I settled on:
   - `node`: hosts, switches, vCenter, appliances.
   - `package`: clusters, vDS, VM groups, sites.
   - `database`: arrays and LUNs.
   - `cloud`: the WAN.
   Nesting a `node` inside a `node` ("Array HQ" holding the controllers) renders fine.
4. **Linking to a package scatters its members under LR.** Layout lever 4 ("link to the package instead of its members") has a cost
   the skill does not mention. PlantUML routes each package edge through an invisible `shape=point` anchor inside the cluster
   (`zaent0003 [shape=point]` in `svek.dot`). The anchor takes a rank, so unlinked members spread into odd 2x2 or triangle layouts
   with empty space (medium VM groups and hosts, large-compute r1). This was the main source of ugly whitespace, and the checker
   does not flag it.
5. **Hidden links under LR.** layout.md's `-[hidden]right-` "nudge" is in practice the only way to stack members in a column under
   LR. I wrongly read `-[hidden]-` as a single dash; it is two dashes, which means the next rank, which means a row.
   - Undocumented: the column comes out in **reverse** operand order, so write `app -[hidden]right- file` to get file below app.
   - It is also overridden whenever real edges attach to the members. ToR A/B only swapped after I reordered the edges themselves.
6. **A same-rank `->` under LR strikes its own label.** The checker's own "too tall" hint says "shorten --> to ->". Under LR that
   makes the edge vertical, and Graphviz centres the label on the line. Fix: use `->` only on unlabelled edges and move the text into
   the node name. The 19:33 checker now reports this as `edge-through-own-label`; the version I started with did not.
7. **Rule 7 does not cover chains that fail in both directions.** For 5-6-rank chains (small, overview, storage) LR was too wide
   and TB too tall every time; flipping just traded one aspect warning for the other. What worked was *folding* the chain: make 1-2
   unlabelled pair edges same-rank. The skill could say: "if both directions fail aspect, fold the chain with `->` on unlabelled
   pairs".
8. **Port groups.** There is no idiom for them. I modelled them as components inside a vDS `package`, linked VM groups to the
   VM-Net port group, and showed pNICs as edge labels (`vmnic0`/`vmnic1`) rather than nodes. Drawing pNICs as nodes would double the
   node count.
9. **The node count is ambiguous.** Rule 6 says "≤ 12 nodes", but the checker's `nodes=` counts only leaves, not packages (medium:
   18 leaves plus 3 packages). The skill should say which count the rule means.
10. **Aspect tolerance is not stated.** `OK` was reported at err +0.27 (1.70 against a 1.29 target, 31% off: k8s large-platform)
    and at 2.01 against 1.78. That is useful to know, but SKILL.md does not give the tolerance.
11. **PDF export (`--preset print`).** The PDF falls short of style.md's "PDF works":
    - Fonts are not embedded (that one is documented).
    - Bold is lost in titles and package names.
    - Unicode box-drawing legend glyphs (`━━━`, `╍╍╍`) disappear, because the font is WinAnsi Type1.
    - The `storage` shape draws as a bracketed box.
    With the title fix in place the shapes are correct.

## (c) Checker false positives and misses (report compared with the PNG)

- **Miss (fixed in the 19:33 checker):** an edge striking its *own* label, on same-rank `->` edges: small r3 (three labels) and
  large-dr r2. The old code explicitly skipped an edge's own label. The current checker reports `edge-through-own-label`; I verified
  it on a copy of small r3.
- **Miss (still present):** crossings at a shared polyline vertex are not counted. In large-compute, `prod-to-torb` and
  `mgmt-to-tora` meet at the same bend point (678.06, 409), which is a visible X, but `crossings=0`. `segs_cross` uses strict
  inequalities.
- **Miss (still present):** edges through unrelated packages are reported only as `info` (`edge-through-cluster`) and leave the
  status OK. In large r3, two WAN-to-DR edges crossed the whole HQ site, which was the worst defect in that render.
- **Miss:** SVG/PDF shapes with no stroke (b1). The PNG looks fine, so neither the checker nor the vision pass can catch it.
- **Miss:** scattered members and empty space inside packages (b4). `density=` is reported but never raised as an issue.
  (medium: density 0.029.)
- **Miss (minor):** labels touching a package border ("2x 25G LAN" on the cluster's bottom edge in medium).
- **Correct finds:** `detached-label` ('host uplinks' 80 px away) and `text-overlap` ('Cluster MGMT' vs 'vmnic1') in large-compute
  were real. I saw no false positives in this family.

## (d) Layout tricks that worked

- **Role columns under LR:** management + VMs | vDS | hosts | ToR + FC | array. Every edge points rightward, and the A/B pair sits
  in one column.
- **Folding a chain:** `->` (same rank) on *unlabelled* pair edges (Veeam->vCenter, VMs->vSwitch, ToR->datastore,
  Veeam->repo), with the text moved into the node name. small went from 4.89 to 1.55, large-dr from 1.81 to 1.41.
- **Member layout under LR:** `a -[hidden]- b` gives a row (next rank); `b -[hidden]right- a` gives a column (same rank, written
  bottom-to-top). Use these to make 2x2 host grids and LUN columns.
- **One edge to a remote site's package** instead of fanning out from the WAN to each DR node. That removed every
  edge-through-cluster crossing in the overview.
- **A pair package** ("ToR pair (MLAG)") instead of a peer-link edge.
- **Colour plus dash per fabric, with a legend** instead of per-path labels. The legend used `<color:#0072B2>━━━</color> fabric A
  (solid)`.
- **Did not help:** `-right->` hints across packages (as layout.md warns). Changing declaration order also did nothing in 3 of 4
  tries; crossing minimisation overrides it.

## (e) Syntax I had to work out outside the skill

- Edge colour and style: `A -[#0072B2]-> B`, `A -[#E69F00,dashed]-> B`.
- Coloured legend swatches: `<color:#hex>━━━</color>` inside `legend ... endlegend`.
- `document { title { ... } }` scoping, as the workaround for b1, found by bisecting the style block.
- How `-[hidden]-` (2 dashes) differs from same-rank `-[hidden]right-`, and the reversed stacking order.
- Diagnosis only: `!pragma svek_trace on` (it is in layout.md) to confirm the package-anchor `shape=point` nodes, and
  `pdftoppm`/`sips` to look at PDF output, since `puml-render` never rasterises its PDF.
