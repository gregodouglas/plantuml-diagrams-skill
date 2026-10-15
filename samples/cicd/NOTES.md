# cicd/ samples: notes from a skill test run

Everything was built by following `skills/plantuml-diagrams/SKILL.md` as written: `puml-new`, then `puml-check --png`, then the Read tool on the PNG, then `puml-render`. Nothing under `skills/` was changed.
Product: a TypeScript web app + API as containers on a managed container platform (Kubernetes), Postgres with migrations, source and CI on GitHub (GitHub Actions).

## (a) Results

| File | Type | Target | Size WxH (SVG px) | Ratio | Final status / issues | Rounds |
|---|---|---|---|---|---|---|
| small.puml | activity, 2 swimlanes | 16:9 | 599x488 | 1.23 | **WARN** `aspect` when first built (err -0.29; the tolerance is 0.29); the current checker reports it as info (fits the slot unscaled; acceptable) | 3 check + 2 look = 5 |
| medium.puml | component (pipeline infra, 15 nodes) | 16:9 | 1395x778 | 1.79 | OK | 3 check + 2 look + 2 simplify = 7 |
| large.puml (overview) | component, 9 stage nodes | letter-landscape | 1009x756 | 1.34 | OK | 2 check + 2 look + 2 simplify = 6 |
| large-1-pr-checks.puml | activity: fork + Playwright matrix partition | letter | 509x737 | 0.69 | OK | 2 (shorter partition title, visible fork bars) |
| large-2-security-build.puml | activity: parallel scans, blocking gate, parallel builds | letter | 453x659 | 0.69 | OK | 2 |
| large-3-preview-staging.puml | activity: switch on trigger, DB snapshot/migrate, smoke | letter | 485x701 | 0.69 | OK | 1 (+ re-check after the bar style change) |
| large-4-production.puml | activity: approval gate, canary repeat loop, rollback | letter | 526x826 | 0.64 | OK | 2 check + 2 look = 4 |

Exports are in `out/`: SVG + 2x PNG for slide, and SVG + PDF + 300 dpi PNG for print.

**Why small is still WARN.** Activity diagrams have no left-to-right mode. After three rounds (adding swimlanes, compacting, removing the trigger action) and two look rounds, the ratio was 1.328 against a threshold of 1.334 (1.23 after the generic relabel). The diagram is 599x488, so it fits a 1200x600 slide with no scaling. I stopped there instead of cutting real steps.

**Why large is split.** The full pipeline has about 45 steps and nodes, well over the 20-node hard cap (rule 6). activity.md also says letter portrait should stay at 20 actions or fewer, then split by phase. So the split is:
- `large.puml`: an overview with one node per stage. The numbers in the nodes match the detail files, the approval gate is the accent, and rollback is folded into the "4b Production" label.
- `large-1` to `large-4`: one activity diagram per stage, each with 7-12 actions.
- The environment matrix (preview / staging / prod) appears as the CD row in the overview and as the `switch` in large-3.
- The build matrix (Node 20/22 x 3 browsers) appears in large-1.

## (b) What the skill lacked or got wrong for CI/CD

- **Activity diagrams cannot reach 16:9.** The checker's aspect hint for activity diagrams says "use left to right direction", which does not exist for activity syntax. activity.md says 12 actions or fewer fits a 16:9 slide, but a 7-action pipeline with one 4-way fork only reaches 1.33. The skill should say that for 16:9, a pipeline flow belongs in a component/LR diagram, or that the activity aspect warning is advisory.
- **Fork bars are invisible inside a `partition`.** The house style gives every element the fill `#F1F5F9`. The fork/join bars get the same fill, so they are barely visible on white and fully invisible inside a partition, which also has that fill. The fix I found by testing selectors is `activityDiagram { activityBar { BackgroundColor #475569; LineColor #475569 } }`. It is not in the template or the references.
- **`skinparam conditionStyle diamond` silently drops the `repeat while (...) is (yes) not (no)` labels.** The template sets conditionStyle diamond, and activity.md documents the `is/not` labels, so the two pieces of advice conflict. I reproduced it in a three-line file. Workaround: `repeat while (Below 100%?\nyes: loop)` followed by `-> no;`.
- **`kill` renders nothing** in this context (it was inside an `if` inside a `repeat`). The branch just dangles. `stop` worked.
- **Early-exit gates.** `if (bad?) then (yes) :fail; stop; else (no) endif` with an empty else produces a long vertical bypass and makes the diagram tall: large-2 was 0.49 and large-4 was 0.36. The fix is to put the happy path inside the then-branch and the exit in the else. That brought them to 0.76 and 0.79. The skill should state this pattern; it is the most common shape in a pipeline with gates.
- **Parallel jobs and matrix builds** have no guidance. What worked: `fork` for jobs, a `partition` around the matrix fork, and a `note right: matrix: Node 20, 22` for a matrix that is not worth drawing as branches.
- **Gates** have no guidance. I used the single `.accent` class plus a legend. With only one accent, "blue" means "blocking gate" in large-2 and "human approval" in large-4, so each file needs its own legend. A second semantic class such as `.gate` would help.
- **Direction hints in component diagrams.** In the LR overview, `-right->` on same-rank `->` edges did nothing. `-left->` made the stacked column read downward instead of upward, which is the opposite of what I expected from "the keywords transpose". The real fix was a different structure (see d).
- **Template body marker.** The style block contains a line `title   { FontSize ... }`. A naive "replace everything from `title` on" edit (which I first wrote) corrupts the file. A `' ---- body ----` marker in the `puml-new` output would prevent this.

## (c) Checker false positives and misses (report vs PNG)

- **Activity diagrams get no edge checks** (`nodes=0 edges=0` in every activity report). Misses I saw:
  - small, round 3: an arrow crossing into the other lane ran across the failure branch's arrow, and crossings was reported as 0.
  - large-1: the join arrow ran straight through the partition title "Playwright matrix: 3 browser shards".
  - The invisible fork bars and the missing repeat labels above.
- **medium:**
  - The "deploy PR" edge passed through its own label, which looked struck through. It was not reported.
  - "request release" crossed two other edges and was reported as `crossings=1`.
  - Components inside packages look borderless because the component line colour is too light against the package fill. There is no contrast check.
- **Aspect false positive.** small (648x488) fits a 16:9 slide without any scaling, but still warns. An aspect warning matters only when scaling would shrink the text or leave large dead areas.
- **Docs mismatch.** For letter-landscape the checker fits to 1056 px, but style.md says about 864x624 is usable. Text-size predictions differ depending on which one you trust.

## (d) Layout tricks that worked

1. **Activity:** swimlanes widened the diagram (ratio 0.88 to 1.18). Putting the failure branch first in an `if` moved the happy path next to the target lane and removed an arrow crossing.
2. **Activity:** happy path in the then-branch, exit in the else (biggest single gain, see b).
3. **Component, rows instead of columns:** use top-to-bottom direction, then `->` (same rank) inside a row and `-->` between rows.
   - Overview: 3.67 to 1.34.
   - medium: `gh -> gha` placed Source next to GitHub Actions instead of above it, going from 0.95 to 1.79 OK.
4. **Link to the package instead of its members** (`gh -> gha : trigger on PR`) removed a crossing through the package title.
5. **Flatten nesting:** taking the Approval gate out of the GitHub Actions package and removing the outer platform package stopped edges from running backwards.

Did not work: `-right->` hints, `-[hidden]right-` order hints, and reordering declarations. The Graphviz input shows these become only `minlen=0`, with no ordering constraint.

## (e) Syntax looked up or worked out outside the skill

- `activityDiagram { activityBar { ... } }`: found by trying four selector names and checking the SVG fill.
- `-> label;` after `repeat while` as the exit-label workaround.
- `partition "..." { fork ... end fork }`, i.e. a fork inside a partition: not stated, but it works.
