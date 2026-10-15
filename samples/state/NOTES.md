# state/ samples: notes from a skill test run (round 2)

Built by following `skills/plantuml-diagrams/SKILL.md` literally. I loaded it with the Skill tool (it was available), then read `references/state.md` and the `state` template. Workflow per file: `puml-new state`, `puml-check --target 16:9 --png`, the Read tool on the PNG, then `puml-render --preset slide --out out`. Nothing under `skills/` was changed. Source: the `*_TRANSITIONS` tables in `samples/ticketing-input/domain.py`; `flows.md` for `large`.

Transition count (each drawn exactly once, none invented): ticket 2, order 12, payment 7, refund 6, event 8 = **35**. The checker's `edges=` matches these counts, because the checker skips `[*]` arrows. Extra arrows that are not table rows: the initial `[*]` arrow in every file (the start state is the dataclass default), the second initial arrow in refund ("created directly as APPROVED inside the refund window"), and final `[*]` arrows in ticket (USED, VOID) and order (EXPIRED, REFUNDED), as the source comments say. Payment, refund and event declare no final states, so I drew none.

## (a) Results

| File | Content | Target | Size WxH (SVG px) | Ratio | Final status / remaining issues | Rounds (check + look) |
|---|---|---|---|---|---|---|
| small.puml | Ticket lifecycle, 3 states, 2 transitions, 2 finals | 16:9 | 485x190 | 2.55 | OK, 0 crossings. info: fits slot unscaled (err +0.36). Two final arrows merge into one end node, as PlantUML draws it | 1 + 1 |
| medium.puml | Order lifecycle, 7 states, 12 transitions, 2 finals | 16:9 | 897x593 | 1.51 | OK, 0 crossings (err -0.16). Reads bottom-left to top-right, Paid ends up top-left, which is odd but legible | 4 + 3 |
| payment.puml | Payment lifecycle, 6 states, 7 transitions, 3-D Secure branch | 16:9 | 722x432 | 1.67 | OK, 0 crossings (err -0.06) | 2 + 1 |
| refund.puml | Refund lifecycle, 6 states, 6 transitions, 2 entries | 16:9 | 745x319 | 2.34 | OK, 0 crossings. Fits slot unscaled (err +0.27) | 2 + 1 |
| event.puml | Event lifecycle, 5 states, 8 transitions | 16:9 | 646x420 | 1.54 | OK, 0 crossings (err -0.14). "refund frees a seat" label is close to "last seat sold" | 2 + 1 |
| large.puml | Overview of 4 machines (Order, Payment, Ticket, Refund): 4 boxes, 8 edges standing for 9 triggers | 16:9 | 660x466 | 1.42 | OK, 0 crossings (err -0.23). One edge merges two triggers; no per-state detail by design | 5 + 3 |

Exports are in `out/`: SVG and 2x PNG (slide preset, exit 0). No letter file, so no print preset.

**Why large is an overview.** The four machines total 22 states and 27 transitions, above the rule 6 cap. Following `state.md` "Several machines", I drew one box per machine ("Order 7 states") and only the cross-machine triggers. Triggers come from `flows.md` F2 to F4: create order and authorize; capture sets Paid; decline sets Payment failed; Paid issues tickets; request refund; approved voids tickets; submitted calls the provider refund; `charge.refunded`; succeeded sets Refunded. I merged "capture sets Paid" and "decline sets Payment failed" into one edge to cut clutter.

## (b) What the skill lacked or got wrong for state diagrams

- **The "rows" recipe is too general.** `state.md` says `->` for the chain and `-->` for branches. It worked for payment and refund. For medium it produced a crossing label (see c) and the table says "TB was enough", but my TB run was too tall (1.23, `warn`). I needed LR plus `-[norank]->`, which `state.md` does not show for this case.
- **The shape table in `state.md` does not match my runs.** It gives order TB 1.38; mine was 1.23 with different labels and one `-up->`. Ratios depend on label text, so a table of exact numbers misleads. A rule of thumb would serve better.
- **No guidance for the overview diagram's layout.** `state.md` says what to draw but not how. Same-rank `->` between boxes collapsed all four boxes into one row (ratio 2.5, 6 to 7 crossings). Plain `-->` with no hints and top-to-bottom was the cleanest. That is the opposite of the rows advice.
- **Not stated: two final arrows draw as one end node.** In small and medium, the two `X --> [*]` arrows meet at one node. Fine, but a reader might think it is a bug.
- **Aspect "too wide" hint still says "stack packages with -[hidden]-> links"**, which does not apply to states. (The "too tall" hint does list rows, so this half was fixed.)
- **Initial state is not in any table.** The skill says nothing about taking the start state from a dataclass default. I did, and said so above.

## (c) Checker false positives and misses (report vs PNG)

- **medium, LR, `edge-through-own-label`, line 45:** true positive. In the PNG a vertical edge ran through "payment captured". The suggested fix (move text into the node or a note) was not useful. Changing `->` to `-->` fixed the label but made the diagram 2.69 wide (`aspect warn`). `-[norank]->` fixed both.
- **payment, first run, `edge-through-text` on 'payment.failed':** true positive. The PNG showed the up-edge from the 3DS state crossing the label. Reordering declarations (Failed before the 3DS state) removed it.
- **large, `text-overlap` 'Payment' / 'failed', `edge-through-text` 'create' / 'authorize':** true positives on the version that used same-rank `->` and `-[norank]->`. Crossings were 6 to 7 on that version.
- **Miss: crossing-free but ugly.** large LR reported OK, 0 crossings. The PNG showed a 2.7 wide diagram with a very long Order to Ticket edge. Ratio 2.73 (err +0.43) was only an `info`, because it "fits the slot unscaled". The checker has no warning for edge length.
- **Miss, small:** err +0.36 is above the 0.29 threshold but only `info`, because of the slot rule. Looks fine in the PNG, so I count this as correct.
- **Counts:** `nodes=` and `edges=` now agree with the diagram (small: 3 and 2).
- **Medium, label touching the edge:** none seen this time.

## (d) Layout tricks that worked

1. **Payment:** TB, chain `Authorizing -> Authorized -> Captured -> Refunded` with `->`, branches with `-->`, and `Failed` declared before the 3DS state. Went from 2.72 with one crossing to 1.67 with none.
2. **Refund:** TB rows with `pending -> Approved -> Submitted -> Succeeded` on one row and Rejected / Failed on the second. 0.84 (tall) became 2.34.
3. **Medium:** LR with `-[norank]->` on the one long edge (Pending payment to Paid), and `-up->` for the two return edges. LR plain gave 1.81 but with a label hit; norank gave 1.51.
4. **Large:** TB with plain `-->` only, no hints. One bidirectional pair merged into a single labelled edge.
5. **Event:** TB with `->` for Draft to On sale and On sale to Sold out, `-up->` for the return edge. 1.12 became 1.54.

Did not work: same-rank `->` between opposite pairs in the overview (collapse into one row); TB plain for medium (too tall, 1.23).

## (e) Syntax looked up or worked out outside the skill

- Nothing outside the skill was needed beyond what `state.md` shows. `state "Long name" as alias`, labelled `[*]` arrows, `-up->` and `-[norank]->` are all in `state.md` or `SKILL.md`.
- `state "Requires action\n(3-D Secure)" as req` (a `\n` in the display name): the skill says `\n` wraps names, and it worked.
- I wrote a small Python helper in the scratchpad to stamp the template preamble onto each body. That is my tooling, not PlantUML syntax.
- `puml-new` creates the file from the template; I replaced the body.

## (f) Compared with round 1

Round 1 gaps (b) and what changed:
- **No state recipe: fixed.** `references/state.md` exists, with skeleton, `hide empty description`, alias, initial and final arrows, composite states, rows and "several machines".
- **Empty compartments: fixed.** `hide empty description` is in the template; no empty boxes rendered.
- **Default direction wrong: partly fixed.** The template is still LR, but `state.md` now says neither pure direction suits and describes rows. Rows worked for payment and refund first try, in 2 checks.
- **Misleading aspect hint: half fixed.** The "too tall" hint now mentions rows. The "too wide" hint still talks about packages.
- **Overview not covered: fixed in text** (one box per machine), **but not in layout**. I still had to find the layout myself.
- **Edge label vs trigger wording: fixed.** `state.md` says event names are fine as labels.
- **Checker counts `[*]` as edges: fixed.** Counts now match.

Round 1 gaps (c) and what changed:
- **Same-rank opposite edges (true positive, hint unhelpful): still hit** in medium (`edge-through-own-label`). The skill now warns about this in `state.md`, but the checker's hint to "move the text into the node" is still not useful.
- **K2,2 crossing in payment: avoided.** Declaring Failed before the 3DS state removed it, so the skill's claim that one crossing always stays was not true for me.
- **Slot definition for "fits unscaled": still unclear.** small (2.55) and refund (2.34) are `info` only. I did not find the slot definition.

New in round 2:
- The shape table of exact ratios in `state.md` did not reproduce for medium.
- No layout advice for the multi-machine overview, and the rows advice makes it worse.
- The checker has no check for very long edges (large LR).
