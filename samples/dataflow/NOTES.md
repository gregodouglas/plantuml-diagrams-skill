# dataflow/ samples: notes from a skill test run

These are data-flow diagrams for a parcel-delivery / courier SaaS. Everything was built by following `skills/plantuml-diagrams/SKILL.md` literally. Nothing under `skills/` was changed.

The skill has no DFD template, so every file was scaffolded with `puml-new component` (on dot). Notation used:

| DFD element | PlantUML |
|---|---|
| Process | `usecase` (ellipse), numbered `0`, `1`, `1.1`, ... |
| External entity | `rectangle` |
| Data store | `database` |
| Trust boundary | `rectangle "Zone" as z_x #white;line:94A3B8;line.dashed { ... }` |
| PII flow | `-[#D55E00,bold]->` plus "(PII)" in the label, so colour never carries the meaning alone; a legend uses `<color:#D55E00><b>` |

## (a) Results

| File | Content | Target | Size WxH | Ratio | Final status / issues | Rounds |
|---|---|---|---|---|---|---|
| small.puml | context DFD: 3 entities, 1 process, 2 stores, 4 boundaries | 16:9 | 711x460 | 1.55 | OK | 1 check + 1 look |
| medium.puml | level-1 DFD: 5 processes, 3 stores, 4 entities (12 nodes, 12 flows) | 16:9 | 1059x613 | 1.73 | **WARN** 1 `edge-through-text` ('Third party' title), 2 `detached-label` (false positives, see c) | 3 check + 2 look + 5 restructure = 10 |
| large.puml | level 0 context: 1 process, 6 entities, 3 stores | letter-landscape | 802x619 | 1.30 | **WARN** 2 `edge-through-text` (App zone / Third party titles), 2 `detached-label` (FP) | 3 check + 2 look |
| large-1-intake.puml | L1 for process 1 (3 sub-processes) | letter-landscape | 665x589 | 1.13 | **WARN** 2 `edge-through-text` (Data zone / Third party titles), 1 `detached-label` (FP) | 3 check + 1 look |
| large-2-assignment.puml | L1 for process 2 | letter-landscape | 830x626 | 1.33 | OK (but see c) | 1 |
| large-3-attempts.puml | L1 for process 3 | letter-landscape | 497x533 | 0.93 | **WARN** `aspect` (fits the page unscaled), 1 `edge-through-text` (Data zone title), 1 `detached-label` (FP) | 3 check + 1 look |
| large-4-proof.puml | L1 for process 4 (4 sub-processes, customs filing) | letter-landscape | 880x556 | 1.58 | **WARN** 1 `edge-through-text` (App zone title) | 3 |
| large-5-billing.puml | L1 for process 5 (payment provider) | letter-landscape | 797x500 | 1.59 | **WARN** 2 `edge-through-text` (Data zone / Third party titles), 1 `detached-label` (FP) | 2 |


Status column is as recorded in the original test run. Re-measured with the current `puml-check` after the title style moved under `document { }` (see the house-style stroke fix): small, large-1, large-2 and large-3 are OK; medium reports 1 `edge-through-text`; large, large-4 and large-5 report `edge-through-text` and one `label-on-border`.

Exports are in `out/`.

**Why the WARNs are left.** Every remaining warning except one `aspect` is the same defect: an edge that enters or leaves a trust-boundary rectangle from above or below and crosses that rectangle's centred title. I tried each lever the skill offers, one per round:
- direction flip (LR to TB and back)
- reordering declarations
- `-[hidden]right-` and `-right->` hints
- linking to the boundary instead of the member
- `frame` instead of `rectangle`, so the title sits on the left
- shorter zone titles

Each either moved the crossing to another title or made the layout worse. In the PNGs the crossings are visible but minor: a line clips 1-2 letters of a zone title.

**Why large is split.** The full system has about 40 elements across 5 processes and 4 boundaries. The split follows the skill's "context diagram + one diagram per subsystem":
- `large.puml`: level 0, showing all external entities and stores around a single process 0 (10 nodes).
- `large-1` to `large-5`: level 1 for each process (7-9 nodes each). Each shows only the entities, stores and boundaries that the process touches.

## (b) What the skill lacked or got wrong for DFDs

- **No DFD type at all.** Neither the "choosing the type" table nor the templates cover DFDs. I had to pick shapes myself:
  - `storage` renders as a stadium/ellipse that is easy to confuse with an ellipse process, so I replaced it with `database`.
  - PlantUML has no open-ended DFD store shape.
  - A `dfd` template (entity / process / store / boundary / PII class and a legend) would remove a whole class of decisions.
- **Trust boundaries.**
  - The skill only shows `package` grouping. The dashed-boundary styling `#white;line:...;line.dashed` is not mentioned.
  - The known rule "edges entering a cluster from above cross its title" (layout.md section 4) gives only "left to right direction" as the fix. DFDs with boundaries on every side hit it in both directions, so the rule needs a second answer. Ideas: a style knob to move the title, or advice to label zones with a corner note.
- **PII marking.** There is no guidance on a second "semantic" accent for edges. The house style has one `.accent` for elements only.
  - `-[#D55E00,bold]->` is only implied by activity.md's `-[#blue,dashed]->`.
  - The legend needed creole `<color>` to show the edge colour, since PlantUML legends cannot draw a line sample.
- **Size limits are counted only in nodes.** medium has just 12 nodes, which meets the "≤ 12 target", but it also has 15 flows and 4 boundaries, and it took 10 rounds. Flows into stores fan in from every process. The rule should also cap edges (about 12) and boundaries (about 3) for 16:9.
- **Reads from stores.** In LR, a store read into the first process becomes a long loop-back edge around the whole diagram (L1 proof, billing). DFD convention lets you duplicate a store symbol, but a duplicate breaks the single trust-boundary box. The most effective simplification was to draw writes only and say "processes hand off via Orders DB; reads omitted" in the legend. The skill should suggest a simplification like this explicitly.
- **Same-rank chains inside a cluster.** In TB, `p1 -> p2` style flows between processes inside the App zone were laid out in reverse order (3, 2, 1) and looped over the zone title. `-right->` and hidden `right` links had no effect. The Graphviz input (`!pragma svek_trace on`) shows they become only `minlen=0`, with no ordering constraint. layout.md says "left/right are hints", but in practice they did nothing in clustered graphs. The skill should say so plainly.
- **Legends.** "Dashed box = trust boundary" and "dashed arrow = append-only write" clash, because both use dashes. A DFD style needs a distinct boundary line (colour or dotted) and an explicit rule about this.

## (c) Checker false positives and misses

- **`detached-label` false positives on long labels.** The checker measures each word. In "attempt + GPS (PII)" or a `\n`-wrapped "(PII)", the last word is 56-82 px from the edge while the label as a whole sits right on it. This appeared in 6 of the 8 files.
- **`aspect` false positive.** large-3 is 503x533, which fits a letter-landscape page (1056 px fit width) with no scaling, but it still warns.
- **Missed: label lying on a boundary line.** In large-2 the "open job address (PII)" label sits on the App zone's dashed border, and the "courier roster" edge runs along that border. The report says OK.
- **Missed: crossings.**
  - medium (TB, with read flows) had about 8 visible edge crossings, reported as `crossings=5`, and only title crossings were raised as issues.
  - The LR medium attempt with 6 crossings had no edge issues at all, only `aspect`.
- **Missed: misleading legend.** The first billing draft had no PII flows but kept the PII line in its legend. There is no check for legend entries that are not used.

## (d) Layout tricks that worked

1. **TB rows by zone:** Public internet on top, App zone in the middle, Data and Third party at the bottom. Write every upward flow with a flipped arrowhead (`server <-[#D55E00,bold]- p2`) so the rows hold. This was the only layout that got medium near 16:9 (1.73).
2. **Write-only flows** (drop store reads; see b): medium went from about 8 crossings to 0 reported.
3. **Grid-wrap the third-party zone** with hidden links (`customs -[hidden]-> msg`, `pay -[hidden]-> geo`): L0 went from 1.82 to 1.31.
4. **LR for a single context process** (small) worked on the first try. The process sits in the middle with zones as columns.
5. Shortening a zone title ("App zone (cloud)" to "App zone", with the runtime moved to the diagram title) cleared one title crossing in medium.

Did not help: `ranksep 60` to `30` in LR (only -6% width, because edge labels are the wide part), wrapping labels to two lines (-5 to 10%), `frame` boundaries, swapping declaration order.

## (e) Syntax looked up outside the skill

- The inline element style `#white;line:94A3B8;line.dashed` for dashed boundary rectangles.
- Mixing `usecase` and `database` inside a component diagram (it works on dot).
- `-[#D55E00,bold]->` coloured and bold edges in description diagrams, and the single-dash variant `-[#D55E00,bold]>` for same-rank edges.
- Creole `<color:#D55E00><b>...</b></color>` inside a legend (labels-and-text.md lists `<color>` but not in a legend context).
