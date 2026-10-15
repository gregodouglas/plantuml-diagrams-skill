# Kubernetes platform samples: test notes

Same setup as `../vmware/NOTES.md`: `puml-new deployment`, then `puml-check`, a PNG look, and `puml-render`. Final numbers come
from the 19:33 version of `puml-check` (the skill was edited while I worked).

Every file carries the house-style workaround `document { title { ... } }`. The stock top-level `title { LineThickness 0 }` strips
node, component and database strokes in SVG and PDF; details in `../vmware/NOTES.md` b1. I applied it before the first check here,
so the round counts below do not include it.

## (a) Results

| File | Target | Size WxH | Ratio | Final status / remaining issues | Rounds |
|---|---|---|---|---|---|
| small.puml (8 nodes) | 16:9 | 1012x564 | 1.79 | OK | 2 + 0 |
| medium.puml (16 nodes) | 16:9 | 1482x816 | 1.82 | OK. Visually, the "syncs" label hugs the staging border | 1 + 2 |
| icons-small.puml | 16:9 | 1012x684 | 1.48 | OK | 2 + 0 |
| icons-medium.puml | 16:9 | 1657x824 | 2.01 | OK, but only after the vision rounds; the 3 checker rounds ended at WARN | 3 + 2 |
| large.puml (overview, 12 nodes) | letter-landscape | 936x646 | 1.45 | OK. Visually, 7 crossings, and 3 arrowheads converge on one point of the prod box | 3 + 1 |
| large-ns-prod.puml (15 nodes) | letter-landscape | 952x757 | 1.26 | OK, with 2 crossings (api->PVC vs worker->redis) | 1 + 1 (no effect) |
| large-platform.puml (15 nodes) | letter-landscape | 947x558 | 1.70 | OK, although err +0.27 against a 1.29 target | 1 + 0 |

Round log:
- **small**: r1 LR 1421x380 (3.74, aspect: a 6-rank chain). r2 made Service->Deployment and PVC->StorageClass same-rank
  (unlabelled) and moved "provisioned by" into the StorageClass name: OK at 1.79.
- **medium**: r1 OK at 1.62, **but the PNG showed the PVC->StorageClass edge running vertically between the words "env," and
  "creds"** (see c). v1 swapped the declaration order of the PVC and the ConfigMap: no change at all. v2 made `pvc --> sc` a
  next-rank edge, so the StorageClass moved right of prod: OK at 1.82 with 0 crossings.
- **icons-small**: r1 default sprites: 1012x820 (1.23, aspect). r2 `<$x,scale=0.5,color=#326CE5>`: OK at 1.48.
- **icons-medium**:
  - r1 1582x1005 (1.57), with edge-through-text on 'ns: platform'.
  - r2 scaled sprites: still that warning.
  - r3 removed the sprites from the namespace titles: still that warning. **Status after the 3 checker rounds: WARN.** Argo CD sat
    directly under the platform title, and its edge to Git left upward through the title text.
  - v1 `-[norank]->` on that edge: worse (it added an own-label strike).
  - v2 reversed the edge (`git --> argo : manifests (pull)`), so Git moves to the left: OK at 2.01.
- **large**: r1 TB 1.53 with 2 edge-through-text. r2 linked to the namespaces instead of their members: 1 left. r3 shortened the
  host labels ("app.*"): 1 left. v1 declared staging before prod: OK.
- **large-ns-prod**: r1 OK. v1 declared the PVC before redis to remove a crossing: it swapped Secret and ConfigMap instead and left
  redis where it was.
- **large-platform**: r1 OK.

**Why large is split.** The full platform is about 40 objects:
- ingress, 3 namespaces with about 12 workload objects in prod alone
- 9 platform add-ons
- CSI
- 6 external services

That is over the 20-node cap. So the split is:
- `large.puml`: the cluster overview, 12 nodes, with namespaces as boxes holding a single "web, api, worker" member.
- `large-ns-prod.puml`: Ingress, Services, Deployments, HPA, StatefulSet, ConfigMap/Secret, PVCs, StorageClass, DB, S3.
- `large-platform.puml`: Argo CD, cert-manager + ClusterIssuer, ingress-nginx, external-secrets, Prometheus, Alertmanager,
  Grafana, Longhorn, and each one's external dependency.

There is no separate staging diagram. It is the same manifests as prod through an overlay (1 replica, no HPA), so a copy would
repeat prod. The overview shows it.

## (b) What was unclear, missing or wrong (k8s-specific; the general items are in ../vmware/NOTES.md)

1. **Namespaces.** The skill does not say which container to use. I chose `rectangle "ns: prod"` inside `node "Kubernetes
   cluster"`: a rectangle reads as a logical boundary, while node and package read as physical ones. That keeps nesting at 2, under
   the limit of 3.
2. **`storage` for PVCs and S3** renders as a stadium or ellipse. It is readable, but PVCs and object storage end up with the same
   shape, which confuses. In PDF it becomes a bracketed box.
3. **Icons (style.md is the only mention).** The guidance is just "sprites enlarge nodes and push the ratio tall; use one
   consistent scale or none". That is true, but missing:
   - **The sprite names.** `plantuml -stdlib` lists the libraries (`k8s`, `kubernetes`) but not their files. `-extractstdlib`
     wrote nothing, and the jar holds packed `.spm` files. I found the names by rendering `listsprites` after the include: `c_role
     cm crb crd cronjob deploy ds ep etcd group hpa ing job limits master netpol node ns pod psp pv pvc quota rb role rs sa sc secret
     sts svc user vol`.
   - **"25pct" is still large**, about 68 px at 1x. With the house FontColor the unlabelled sprites render grey with **dark square
     corners**, which looks broken. `<$ing,scale=0.5,color=#326CE5>` fixes both the size and the corners (light corners in K8s
     blue).
   - Adding a sprite to a label **left-aligns the whole label** under the icon.
   - **A sprite in a package title makes the title taller**, and edges leaving members near the top then cross the title text. That
     caused the r1-r3 warnings on icons-medium.
4. **Ingress controller vs Ingress object.** No guidance on this either. I drew the controller (cluster-scoped, in platform) apart
   from the Ingress resource (namespaced, in prod). Otherwise the overview and the namespace detail disagree.

**How the icons affected size, ratio and checker results:**

| Pair | Height | Ratio | Checker |
|---|---|---|---|
| small → icons-small, default 25pct sprites | 564 → 820 (+45%) | 1.79 → 1.23 | new `aspect` warning |
| small → icons-small, `scale=0.5` | 684 (+21%) | 1.48 | OK |
| medium → icons-medium (r1) | 816 → 1005 | 1.82 → 1.57 | new `edge-through-text` (sprite-tall namespace title); needed 3+2 rounds instead of 1+2 |

- `nodes`, `edges` and `texts` are unchanged; the sprites are invisible to the text and geometry checks.
- The final icons-medium is the widest of all the samples (2.01), because of the reversed Git edge.

## (c) Checker false positives and misses

- **Miss (still present on the 19:33 checker):** an edge passing *between the words* of a multi-word label. PlantUML emits one
  `<text>` per word, and the checker shrinks each box by 2 px. In medium r1, the vertical PVC->StorageClass segment at x=1042.97 ran
  between "env," (ends 1038.2) and "creds" (starts 1041.5). That reads as a strike-through, but the status was OK. I re-verified
  this on a copy with the current checker. Suggested fix: merge the word boxes of one label before the hit test.
- **Miss:** three arrowheads converging on the same point of a package border (large: ingress "app.*", Prometheus "scrapes" and
  Argo "syncs" all land at prod's top-right). Nothing flags it.
- **Miss:** `crossings=7` in large is reported but raises no issue. The `many-crossings` info threshold (≥ max(4, edges) = 14) is
  high for an overview.
- **Correct finds:** `edge-through-text` on 'ns: platform' (icons-medium) and on 'staging.*' (large) were real. The new
  `edge-through-own-label` fired correctly when `-[norank]->` laid the Git edge across its own label. No false positives seen.

## (d) Layout tricks that worked

- **TB for the print detail diagrams** (the `--preset print` default). The namespace detail is naturally layered (Ingress ->
  Service -> Deployment -> config/PVC -> StorageClass) and fitted letter-landscape on the first try.
- **LR plus same-rank unlabelled edges** for the slide sizes (Service->Deployment, Grafana->Prometheus).
- **Reversing an edge's direction** to move a node to the other side: `git --> argo` put Git left of the cluster instead of above
  the platform title.
- **Linking to the namespace** rather than its single member in the overview. With one member per namespace there is no anchor
  scatter (see vmware b4), and edges stop crossing the namespace titles.
- **Sprites:** `scale=0.5,color=#326CE5`, and no sprites in container titles.

## (e) Syntax I had to work out outside the skill

- The sprite set and its names (`listsprites`), and the sprite parameters `<$name,scale=0.5,color=#hex>` (`<$name{scale=0.5}>`
  also works).
- `rectangle "..." as x { }` as a namespace frame, and the `storage` keyword.
- `-[norank]->` is in the skill; it did not help here.
