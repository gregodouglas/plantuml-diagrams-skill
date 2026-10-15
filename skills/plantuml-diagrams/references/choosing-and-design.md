# Choosing the diagram and designing its content

## Write the takeaway first
One sentence: "This diagram shows that ___." If the sentence needs more than ~5 bullets to explain, split (Google tech-writing).
Prefer a **table** when the content is a mapping or matrix with no flow or topology (env var → service → secret source).

## Question → type
| Question | Type | Template |
|---|---|---|
| Who talks to whom, in what order? (API, auth, webhook) | sequence | `puml-new sequence` |
| What are the steps, decisions, owners? | activity (+ swimlanes) | `puml-new activity` |
| What states can X be in and what moves it? | state | `puml-new state` |
| What are the parts and dependencies? (dev audience) | component | `puml-new component` |
| Same, for non-developers / stakeholders | C4 context or container | `puml-new c4-context` / `c4-container` |
| Where does it run? | deployment | `puml-new deployment` |
| What is the data shape? | ER (tables) or class (code) | `puml-new er` / `class` |
| What is in scope and who uses it? | use case or C4 context | `puml-new usecase` |
Not covered by templates but valid: object, timing, Gantt, mindmap, WBS, JSON/YAML, network (nwdiag), Salt wireframes, archimate.

## Limits (policy, tunable)
- One takeaway per diagram. ≤ 12 nodes target, 20 hard cap. ≤ 7 top-level groups, ≤ 3 nesting levels.
- Edge labels ≤ 4 words, verb first, read in the arrow's direction. Unlabelled is better than "uses".
- One dominant flow direction. Consistent arrow semantics (solid = call, dashed = async/event, state as separate legend entries).
- Legend whenever colour, shape or line style carries meaning. Title = type + scope ("Container diagram: Order API").
- Over the cap: split by subsystem or phase (context diagram + one diagram per subsystem), not a bigger diagram.
- Edge crossings are the biggest readability killer (Purchase 1997); fewer crossings beat symmetry and short edges.

## Inventory before code (the verifiable intermediate)
```
nodes: alias | label | group        (count them; split if > 20)
edges: from -> to : label           (≤ 4 words)
direction: TB | LR                  (TB for hierarchies/trees; LR for chains, pipelines, layered flows on slides)
target: 16:9 | letter | none
```
Then scaffold (`puml-new`), fill in, check, look, fix (max 3 rounds), export.
