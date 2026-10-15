# c4/ samples: notes from a skill test run (round 2)

I drew five C4 views of the invented Venue Ticketing system from `samples/ticketing-input/ARCHITECTURE.md` only. I loaded the skill with the Skill tool (it worked; I did not read SKILL.md directly), then followed the workflow: `puml-new`, `puml-check --png`, a look at each PNG, `puml-render`. Nothing outside `samples/c4/` was changed. The container view is split into a sales path and an async path for slides, and drawn whole for print. Platform admin appears only in the context view: the input gives the admin no container to use, so an edge would be invented (rule 12). Exports are in `out/`: SVG + 2x PNG for slide files, SVG + PDF + 300 dpi PNG for the print file.

## (a) Results

| File | Content | Target | Size WxH (SVG px) | Ratio | Final status / remaining issues | Rounds (check + look) |
|---|---|---|---|---|---|---|
| context.puml | 3 people, Venue Ticketing (accent tag), 3 external systems; 7 nodes, 7 edges | 16:9 | 1075x648 | 1.66 | OK. Admin edge label shortened to "Onboards" (see c). Legend swatches show as boxes. | 4 + 4 |
| container.puml | Sales path: 2 people, Fan web app, Staff app, Ticketing API (accent), Database, Seat-hold cache, IdP, Payment provider; 9 nodes, 11 edges | 16:9 | 1202x718 | 1.67 | OK, 1 crossing (Fan app to API crosses Staff app to IdP). The "Venue Ticketing" system boundary was dropped (see b). Staff app to IdP edge has no label on purpose. | 3 + 3 |
| container-async.puml | Async path: Payment provider, API, Job queue, Worker (accent), Database, Ticket store, Email service; 7 nodes, 6 edges | 16:9 | 978x621 | 1.58 | OK, 0 crossings. Worker sits mid-left with empty space below it. | 1 + 1 |
| component.puml | 8 API components inside a boundary, plus Database, Seat-hold cache, Job queue, IdP, Payment provider; 13 nodes, 14 edges; Payments in accent | 16:9 | 1516x793 | 1.91 | OK per checker, min font 9.5 px, 2 crossings. In the PNG the Database edges are long and run across the boundary; only one of six carries the label "Reads/writes". | 3 + 3 |
| container-print.puml | All 8 containers + 2 people + 3 external systems; 13 nodes, 16 edges; `--preset print` | letter-landscape | 1250x945 | 1.32 | WARN `tiny-text`: 7.6 px at 864 px wide. Ratio is on target. 1 crossing. `busy` info (16 edges). | 5 + 5 |

**Why the container view is split.** One view has 13 nodes and 16 edges: over the slide limits (rule 6), under the 20-node cap. I split by path and repeated the API and Database where both paths use them. The print file keeps everything.

**Why component is 16:9.** The Ticketing API has 8 components and 5 outside neighbours, so the view is wide. Top-down with grid-wrapping reached 1.91 with 9.5 px text. Left-to-right was 0.95 (tall, long loops). A slide takes the wide shape; letter-landscape would shrink the text below 9 px.

## (b) What the skill lacked or got wrong for C4

- **No lever for a wide row of leaf nodes in C4 print view.** Top-down put 7 leaf nodes in one row (2.30, 5.7 px text). The skill's grid-wrap uses hidden links inside a package; with C4 elements I tried `Lay_D(db, store)` and `Lay_D(cache, email)`. That moved two nodes and gave 1.82. What worked was reversing one edge's direction: `Rel_U(worker, queue, ...)`, which puts the queue above the Worker and adds a rank (0.996). The skill does not describe this.
- **Print trade-off not stated.** Widening with `nodesep 80` / `ranksep 40` reached the 1.29 target but left 7.6 px text (`tiny-text` warn). The skill does not say which to give up when a 13-node, 16-edge view must be one page.
- **Boundary advice does not fit this input.** `c4.md` says to put people and externals beside the boundary. Here both apps (inside) connect to the IdP, so the edges must leave the boundary from the app side and crossed the title. I dropped the `System_Boundary` and lost the "this is one system" box. The skill gives no other option (shorter title, title position, or accepting the crossing).
- **Component view limits.** 13 nodes and 14 edges is over rule 6, and a split would leave a component view without its neighbours. The skill has no guidance for one container with many components. Repeated edges to one target (6 to the Database) need the "label one, blank the rest" trick; `c4.md` mentions it only for the IdP case.
- **Legend swatches are still boxes.** `c4.md` now explains it is the `▯` border swatch (U+25AF). In my PNGs it renders as an empty box next to every legend entry, which looks like a missing glyph to a reader of the sample.
- **`$legendText` is not mentioned.** The tag legend entry reads "accent" unless you pass `$legendText`. `c4.md` says the legend lists the tag automatically, which is true but the default name is meaningless. I used `$legendText="System in focus"` etc.
- **Context at 1.33 passes.** With the default `ranksep 60`, the first context render was 1.333 vs 1.778 (err -0.29) and the checker said OK. The `ranksep 110` tip in `c4.md` was not enough here; 170 worked (see d).

## (c) Checker false positives and misses (report vs PNG)

- **Line numbers now point at source lines.** Every warning I got carried a line of my file, and the ones I checked were right: context `line 48` was the `Rel(admin, ...)` line; container `line 41` was the `System_Boundary(...)` line. (The TB component warnings `line 55` and `line 60` also pointed into the Rel block, in that version of the file.) Round 1's SVG-line problem did not appear.
- **True positive, context:** `edge-through-own-label` on "Onboards venues". In the first PNG the line grazed the end of the label. After `Rel_R` the file got worse (admin above, vertical edge through the label) and the same warning stayed, which was correct. A shorter label ("Onboards") cleared it.
- **True positive, container:** `text-overlap` of the boundary title with "[OIDC, PKCE]". The PNG showed the same collision.
- **True positives, component (top-down, before grid-wrap):** `detached-label` ("Reads/writes" 50 px from its edge), `label-on-border` on "Validates tokens", `aspect` 2.59, `tiny-text` 8.8. All matched the PNG.
- **Misses:** (1) Context at ratio 1.33 reported OK. (2) container-print with `Rel_U` reported OK at 0.996 vs target 1.294 (err -0.26, just under the 0.29 line); the PNG was square with a lot of empty space. (3) component: OK with 2 crossings, but the PNG shows long Database edges and five blank labels; no check for edges that run a long way past other nodes.
- **No false positives this run** that I could confirm from the PNGs.

## (d) Layout tricks that worked

1. `skinparam ranksep 170` for left-to-right context: 1.33 to 1.66. For container, `ranksep 120`: 1.42 to 1.67.
2. Shorter edge label ("Onboards") to clear `edge-through-own-label`.
3. Dropping the system boundary to remove the title crossing.
4. Split by path with shared containers repeated.
5. `Lay_D(holds, auth)`, `Lay_D(payments, catalogue)`, `Lay_D(ticketing, door)` in a top-down component view: three rows of three instead of one row of eight (2.59 to 1.91).
6. `Rel_U(worker, queue, ...)` in the print view: adds a rank, turned a 1.8-2.3 wide layout into a compact one (then `nodesep 80`, `ranksep 40` to reach 1.32).
7. A blank label `" "` on parallel edges to the same target.

Did not work: `Rel_R(admin, vt)` (put the admin above the system); top-down for the full container view (2.30); left-to-right for the full container view (0.89, long diagonals); `Lay_D(db, store)` / `Lay_D(cache, email)` (1.82, 3 crossings).

## (e) Syntax looked up or worked out outside the skill

- `$legendText` in `AddElementTag(...)` to name the tag's legend entry.
- That `Rel_U(a, b)` draws b above a (so the arrow points up and the rank changes), and that `Rel_R` forces the same rank.
- `ContainerQueue`, `ContainerDb`, `System_Ext` calls: in the templates and `c4.md`.
- `Lay_D` in a grid inside a `Container_Boundary`: the skill lists `Lay_*` only generally.
- Dropping a `System_Boundary` as a layout fix: my decision, not in the skill.
- I ran `puml-new` once for each C4 type to see the templates and deleted the scratch files; I saved two layout variants in the scratchpad, not in the repo.

## (f) Compared with round 1

Round 1 gap (b), what the skill lacked:
- **No component template: fixed.** `puml-new c4-component` exists and `c4.md` gives the `Component` argument order.
- **House style does not reach C4: fixed in the docs.** `c4.md` says `<<accent>>` has no effect and gives the tag mechanism; it worked for me.
- **Legend tofu: documented, not fixed.** I still see empty boxes in every legend.
- **Boundary title collisions: documented, still hit.** The advice did not apply to my container view; I dropped the boundary.
- **Shared edge labels: documented** (`" "`), worked.
- **Direction choice by measurement: fixed.** SKILL.md rule 7 says to compare directions; I did, for container, component and print.
- **Aspect "fits unscaled" info hiding wide diagrams: not seen this run.** The wide component was reported as a warning until I fixed it.

Round 1 gap (c), checker:
- **Line numbers pointing into the SVG: fixed** for the warnings I got.
- **Crossings count not warned:** I did not hit a large-crossing case this time (max 2-3); untested.
- **`tiny-text` formula versus width:** still a trade-off; I hit it in print (7.6 px at the target ratio).
- **False positive on "Consumes":** not reproduced; this run's warnings were all true.
- **Legend tofu undetected:** still undetected.

New this round: no lever for a wide leaf row in C4 (found `Rel_U`), no guidance on print trade-off, no `$legendText` mention, and the dropped system boundary.
