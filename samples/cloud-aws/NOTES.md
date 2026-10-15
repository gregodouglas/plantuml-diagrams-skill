# cloud-aws/ samples: notes from a skill test run (round 2)

Source: `ticketing-input/infra.md` (invented "Venue Ticketing" AWS deployment). I used the Skill tool (`plantuml-diagrams`), and it loaded SKILL.md. I then read `references/domains.md` (cloud recipe) and `references/style.md` (sizing, themes) as SKILL.md points to them. Nine diagrams: small, icons-small, medium, icons-medium, and a large set (overview plus four detail files). Final exports are in `out/` (slide preset: SVG + 2x PNG; print preset: SVG + PDF + 300 dpi PNG). Sizes below are from the last `puml-check` (SVG px).

## (a) Results

| File | Content | Target | Size WxH | Ratio | Final status / remaining issues | Rounds (check + look) |
|---|---|---|---|---|---|---|
| small.puml | Fan, Route 53, CloudFront+WAF, S3 static, ALB, api, RDS; plain shapes | 16:9 | 758x279 | 2.72 | OK, info only ("fits slot unscaled"). Wide strip, fills little of the slide. TB gave 0.58 and was worse | 3 + 2 |
| icons-small.puml | Same content, AWS icons | 16:9 | 725x327 | 2.22 | OK, no warnings. Closer to 16:9 than the plain one (icons make nodes taller) | 1 + 1 |
| medium.puml | VPC, public/private subnets, ALB, NAT, api, worker, RDS pair, Redis pair, SQS+DLQ, S3, SES, Identity, Payment | 16:9 | 1153x772 | 1.49 | Checker OK. PNG: worker's three edges to SQS/S3/SES share one trunk, labels sit on the trunk; Identity/Payment order reversed; ratio still 16% short. Merged AZ pairs into single nodes (rule 6) | 9 + 7 |
| icons-medium.puml | Same, icons | 16:9 | 1113x882 | 1.26 | WARN aspect (too tall). Same trunk bundling as medium; External boxes have no icons (no matching sprite chosen) | 1 + 1 |
| large.puml | Overview, 12 nodes, no icons | letter-landscape | 1024x876 | 1.17 | WARN: `jobs`/`via NAT` label on border, `logs` detached from edge (my `--->` made long bent edges). Text 9.3 px at fit | 3 + 3 |
| large-edge.puml | Route 53 names, CloudFront, WAF, ACM, S3, ALB, webhooks | letter-landscape | 732x416 | 1.76 | OK (info only) | 1 + 1 |
| large-network.puml | VPC, public/private subnets, ALB, 2 NAT, endpoints, external | letter-landscape | 755x659 | 1.15 | WARN: `target group` edge runs near the "Private subnets" title (PNG: close, not struck) | 2 + 2 |
| large-compute-data.puml | api, worker, ECR, Secrets Manager, RDS, Redis, SQS+DLQ, S3, SES | letter-landscape | 774x575 | 1.35 | OK | 2 + 1 |
| large-ops.puml | CloudWatch, alarms, SNS, on-call | letter-landscape | 505x359 | 1.41 | OK | 3 + 1 |

Rounds above count `puml-check` runs including direction flips. The skill says "max 3 rounds"; medium needed far more.

Scope choices (rule 12): the medium and large diagrams draw AZ pairs (RDS primary/standby, Redis primary/replica, NAT per AZ) as one node with both roles in the label, because of the 12-node cap. The brief asked for primary/standby as separate boxes; I followed the skill. The worker-to-Redis relation is not in infra.md, so it is not drawn.

## (b) What the skill lacked or got wrong for cloud architecture diagrams

- No guidance on how to draw one service that talks to many sinks (worker to S3, SES, SQS). Three edges leave one node and bundle into one trunk under both directions. The recipe says "push sinks out with `--->`"; that made long, bent edges and, in large.puml, labels detached from their edges.
- The 12-node cap conflicts with a request for "VPC, two AZs, primary/standby, replica, NAT per AZ". The recipe says merge pairs, which works, but then "two AZs" is only text in labels. No guidance on when an AZ box is worth the nesting cost (it is: large-network shows it with subnets as AZ-labelled nodes).
- AWS icon sprite names are not listed. The recipe names five paths. I needed about fifteen more (Route53, WAF, ElasticLoadBalancing, VPCNATGateway, ElastiCache, SimpleEmailService, ...). `ApplicationLoadBalancer` does not exist; `ElasticLoadBalancing` does, and `SimpleEmailService` is under `BusinessApplications`, not `CustomerEnablement`. Guessing costs a render each.
- No example for a short list of "regional services outside the VPC" (SQS, S3, SES). I first put them in a container; the container title was then struck by edges. Removing the container fixed it.
- Rule 7 says to flip direction when `aspect` fires. For medium, TB gave 2.6 (wide, tangled), LR gave 0.80 then 1.49 after other changes. The order of operations (flip direction, then restructure) is not in the skill; I found it by trial.
- The skill does not say what to do when a checker says OK but the PNG is bundled (see c).
- `puml-new deployment --title x` without `--preset` produced the document variant; the skill's step 3 shows `[--preset ...]` optional. For a 16:9 file the preset is not optional in practice (my first medium run was TB with 12 pt text). Minor, but it cost a round.

## (c) Checker false positives and misses

Line numbers: all warnings pointed at the right lines of my files. This held for files with the awslib `!include` lines at the top (icons-small, icons-medium): the reported `edge-through-text`/`label-on-border` lines matched the edge lines in those files (I checked `sed -n Np`). No offset.

Misses (checker clean or info-only, PNG not clean):
- medium.puml: `OK`, but the worker's edges to SQS, S3 and SES leave as one trunk and the labels `consume`, `PDFs`, `send email` sit on top of each other's paths. Nothing reported it. `crossings=2` was printed but not flagged.
- icons-medium.puml: same, and `crossings=4`.
- small.puml: `aspect` is only `info` at 2.72 because it "fits unscaled", but the diagram fills 38% of the slide at the first try. Acceptable per the checker, weak as a slide.

True positives that were useful: `edge-through-text` on container titles (VPC, Private subnets) in medium; `label-on-border`; `detached-label` for `logs` in large.puml; `tiny-text` on the first large.puml (8.9 px). The `edge-crosses-nested-borders` info appeared on almost every edge in the first medium and was noise once I could not avoid nesting.

False positive / questionable: in the medium file the checker flagged `edge-through-text` on 'Private subnets (no public IPs)' for the api-to-NAT edge. This was true. After I shortened the title to "Private subnets" the checker kept flagging it; the PNG showed the edge passing close to, not through, the text. So the check is conservative, not wrong. In large-network the `target group` edge is flagged the same way, and the PNG shows a near miss.

## (d) Layout tricks that worked

- Same-rank unlabelled edge to fold a chain (`api -> rds` in small.puml, LR): 3.55 to 2.72.
- Flip the arrowhead, not the operands (`nat <-- api`, `worker <-- sqs`): keeps rows in order while the arrow points the right way. This put NAT above the private subnet in TB.
- Link to a container when the edge ends at a boundary (`cf --> pub`, `nat --> ext`): removed the title strikes. It did not help when two edges targeted the same container (they merged into one tangle, so I reverted that for api/worker to NAT).
- Removing a container whose only role was "AWS managed services": cleared a title strike and cut width.
- Shortening container titles and moving the extra text to the legend ("Private subnets have no public IPs").
- Direction compare per rule 7: TB for medium looked fine at first run but LR won at the end (1.49 vs 1.25); for compute-data TB gave 2.38 (too wide, same rank) and LR gave 1.35; for ops, TB (0.65) became 1.41 after making `alarm -> sns -> oncall` same-rank.
- Icons with `scale=0.5` in a `rectangle`, includes placed before the `<style>` block: house style kept; no overlap.

## (e) Syntax looked up or worked out outside the skill

- `skills/plantuml-diagrams/` had nothing on the sprite names used below. I probed the paths in a scratch dir by rendering a one-node file per path (listing the jar showed only directory stubs, not file names). Every path below rendered and the icon showed in the PNG.
  - Beyond those the skill names (CloudFront, RDS, Fargate, SimpleQueueService, AWSCommon):
    `awslib/NetworkingContentDelivery/Route53`, `awslib/SecurityIdentityCompliance/WAF` (included in icons-small.puml, sprite not drawn: WAF is merged into the CloudFront node), `awslib/Storage/SimpleStorageService`, `awslib/NetworkingContentDelivery/ElasticLoadBalancing`, `awslib/NetworkingContentDelivery/VPCNATGateway`, `awslib/Database/ElastiCache`, `awslib/BusinessApplications/SimpleEmailService`.
  - Probed and failed (not used): `NetworkingContentDelivery/ApplicationLoadBalancer`, `NetworkingContentDelivery/NATGateway`, `NetworkingContentDelivery/VPC`, `CustomerEnablement/SimpleEmailService`.
  - Probed and OK, not used: `General/Users`, `SecurityIdentityCompliance/SecretsManager`, `ManagementGovernance/CloudWatch`, `Containers/ElasticContainerRegistry`, `NetworkingContentDelivery/VPCEndpoints`.
- Same-rank edge (`->`) behaviour under LR, `worker <-- sqs` (arrowhead flip, row order kept): from `references/layout.md`/`domains.md` patterns, not new.
- `sed -i ''` for edits and a small Python helper to swap the body of a scaffolded file; shell tooling only, not PlantUML syntax.

## (f) Compared with round 1

Round 1 gaps (b) that the revised skill fixed for me:
- No AWS recipe / nesting advice: fixed. `domains.md` now says AZ goes in the label, VPC with public/private subnets as containers. I followed it for medium and it worked (no 4-level nest).
- `cloud` vs `rectangle`: fixed. The recipe says `rectangle "AWS (production)"`. My small.puml used it from the start, no bumpy outline.
- Icons undocumented, `AWSCommon` mandatory, include order: fixed. The recipe gives the include path form, `AWSCommon` first, includes before the `<style>` block, and the quoting form. icons-small rendered on the first run with no stray quotes and slate arrows.
- Pair stacking and `--->` for sinks: fixed (in the recipe). I used them. They worked for pairs but made detached labels in large.puml (see below).
- Direction vs rule 7: partly fixed. SKILL.md rule 7 now tells me to flip and compare, which I did (TB and LR on small, medium, compute-data, ops).
- Checker counts notes as nodes: not retested (I used no notes).

Round 1 gaps (c) status:
- Miss on the `cloud` outline: moot (I used `rectangle` for the AWS boundary and no `cloud` shape).
- Stale PNG on exit 2: not hit (no exit 2 in this run).
- `tiny-text` message saying "cut content": still the same wording; it fired once (large.puml 8.9 px) and a layout change fixed it. Now the message says "change direction or build rows", which matches what worked. That part is improved.
- Aspect `info` "acceptable" on a banner (small.puml 2.72): still there. It now adds "fills 38% of the slot, a direction change or rows would use it better". Useful, but the fix suggested did not help (TB was worse).

Still hit:
- Sink fan-out. The worker's three edges to S3/SES/SQS bundle into one trunk, and the checker is silent (crossings are counted, not flagged). Same as round 1's "3 crossings, long SQS/S3/SES edges".
- 16:9 is not reached for medium. Round 1 got 1.64; I got 1.49 (checker OK) and 1.26 for the icon version. I did not do better on ratio, mainly because I kept AZ-labelled nodes and the VPC/subnet containers as the recipe says.
- `edge-through-text` on container titles. Still the main time sink in the large-network and medium files. The rule "link the container" helps for one edge, not for two edges to the same container.

New:
- The "max 3 rounds" rule is not realistic for a 12-node, 12-edge, 3-container cloud slide: medium took 9 check runs.
- The recipe's `--->` advice produces bent long edges and detached labels when the sink edges carry labels; no advice to drop those labels.
- Icon sprite names: only five are listed; `ElasticLoadBalancing` and `SimpleEmailService` locations are not given. Round 1 had a different ALB sprite name (`ElasticLoadBalancingApplicationLoadBalancer`); I used `ElasticLoadBalancing`. Both render.
- `puml-new` without `--preset` gives a document-style template; I lost one round on it.
