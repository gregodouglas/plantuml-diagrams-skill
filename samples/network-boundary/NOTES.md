# network-boundary: field-test notes for the plantuml-diagrams skill

Domain: perimeter / boundary network diagrams for MSP client documentation (zones, HA firewalls, DMZ, cloud links).
Everything was scaffolded with `scripts/puml-new deployment ...`, checked with `scripts/puml-check ... --png`, inspected
as PNG, and exported with `scripts/puml-render` (slide preset for small/medium, print preset for large*). PlantUML
1.2026.8, Graphviz 15.1.1.

## (a) Results

Final `puml-check` status for every file is **OK**. "Rounds" = check-fix iterations after the first check (the
"look" pass on the PNG is counted separately).

| File | Target | Size (SVG px) | Ratio | Issues on first check | Final issues | Rounds (+look) |
|---|---|---|---|---|---|---|
| small.puml | 16:9 | 955x478 | 2.00 | aspect 2.50 | none | 2 (+1: actor stroke, strike-through label) |
| medium.puml | 16:9 | 1933x852 | 2.27 | aspect 2.46, edge-through-text, png-cropped | info many-crossings (18) | 2 |
| large.puml (overview, 15 nodes) | letter-landscape | 1066x987 | 1.08 | detached-label (false positive) | none | 1 |
| large-hq-perimeter.puml | letter-landscape | 961x836 | 1.15 | edge-through-text (DMZ title) | none | 1 (+1: label struck by own edge) |
| large-hq-internal.puml | letter-landscape | 1052x963 | 1.09 | aspect 1.74, tiny-text, edge-through-text, detached-label | none | 2 (+1: ambiguous labels) |
| large-branch.puml | letter-landscape | 766x599 | 1.28 | detached-label x2 (false positives) | none | 1 |
| large-cloud.puml | letter-landscape | 831x823 | 1.01 | aspect 0.95, edge-through-text x3, nested-borders, detached-label | none (1 real crossing) | 3 |

Exports in `out/`: `*.svg` + `*.png` for all; `*.pdf` for large*.

### Why the large size was split
Inventory for the multi-site design was ~35 distinct nodes in 9+ groups, well over the skill's caps (12 nodes soft /
20 hard, 7 groups). Split by site/function so each detail stays at 8-14 nodes:
- `large.puml`: overview with zones as nodes (exactly 15: HQ zones, branch, Azure hub, Entra/M365). Its legend names the detail files.
- `large-hq-perimeter.puml`: internet, ISP links, HA pair, DMZ (WAF, web, mail relay, VPN).
- `large-hq-internal.puml`: core + internal FW, server/user/mgmt zones, OT/ICS behind an OT firewall, IoT, guest.
- `large-branch.puml`: branch SD-WAN FW, branch VLANs, local guest breakout.
- `large-cloud.puml`: ExpressRoute + VPN backup, Azure hub/spoke, Sentinel, Entra/M365.
Cross-diagram anchors are drawn as `<<muted>>` stub nodes with "(see X)" in the label.

## (b) What the skill was unclear about, missing, or wrong for this domain

1. **No network-diagram type in the type table.** "Where does it run?" leads to `deployment`, which is workable, but
   nothing says how to draw trust zones, firewalls, HA pairs, subnets or flows. I invented the conventions: zones as
   `rectangle "Name  CIDR" as x #fill { ... }`, the firewall as the single `<<accent>>`, protocol/port as edge labels,
   cross-diagram stubs as `<<muted>>`. A short "network/zone" recipe in `choosing-and-design.md` (or a `network`
   template) would save every agent from working this out again.
2. **House-style bug: actors render without a stroke in description diagrams.** `title { ... LineThickness 0 }` in the
   inlined style also applies to `actor` in deployment/component/usecase diagrams. The SVG stick figure has no stroke at
   all (invisible in browsers); the PNG shows a faint ghost. I confirmed this in the shipped `deployment`, `component`
   and `usecase` templates; sequence actors are fine. A `title { LineColor ... }` change leaks into actors too.
   Workaround I used: add `actor { LineThickness 1.2 }` **after** the `title` rule (order matters; putting it before
   does nothing). The checker does not catch this.
3. **Colour-coded trust levels don't fit the "accent on 1-3 elements" rule.** Trust zones need 4-6 fills plus a legend.
   The skill allows a legend but gives no palette for zones. The light fills I picked (#FEF2F2/#FFF7ED/#F0FDF4/
   #F5F3FF/#FEFCE8) are hard to tell apart, especially inside a `rectangle` that already has the house #F1F5F9 fill (see
   large.png). A tested zone palette, stronger zone borders, or a `.zone-untrusted` / `.zone-dmz` / ... class set in the
   house style would help.
4. **Legend tables look heavy.** `|= a |= b |` inside `legend` draws thick black cell borders and cramped cells, which
   clashes with the slate house style. No guidance on styling legend tables.
5. **HA pairs:** nothing on drawing one. `fwa - fwb` inside a rectangle works, but a label on that same-rank edge is
   always struck through by its own line (see medium round 1). I moved "HA active / standby" into the rectangle title.
6. **ISP links / dual uplinks:** two parallel labelled edges from the same pair (`inet --> fwpair : ISP A`, `: ISP B`)
   work, but the labels sit on the bends. Folding the ISPs into edge labels instead of nodes also cut one rank, which
   fixed the medium diagram's aspect.
7. **Icons:** `style.md` lists stdlib icon sets (`<azure/...>`, `<awslib/...>`) but gives no tested example and warns they
   make shapes tall. I used none. A tested Azure firewall / VPN gateway sprite snippet would be welcome; the default
   `node` box for everything reads as generic.
8. **No size guidance for overview-plus-detail sets.** Rule 6 says "split ... and say so", but not how to keep the parts
   consistent (stub nodes, shared colours, naming). I used muted stubs plus a legend line pointing at the detail files.
9. **puml-new + print preset defaults to top-to-bottom.** That was right for most of the detail diagrams, but the
   SKILL.md checklist tells you to use `--target letter-landscape` for large overviews, and a TB layout is usually
   taller than landscape. Square results (ratio 1.0-1.1) still pass because the tolerance is |ln(ratio/target)| <= 0.29.
   That tolerance is only written down in `toolchain.md` / the script. SKILL.md shows `err=` without explaining it.

## (c) Checker false positives and misses (report vs PNG)

False positives:
- **detached-label on the trailing words of a multi-word label.** `ISP A + ISP B` -> "'B' is 62px from its edge";
  `broadband + LTE` -> '+' and 'LTE'; `HTTPS from jump` -> 'from', 'jump'; `IPsec S2S backup` -> 'backup'. In every
  case the label sat right beside its (near-vertical) edge. PlantUML emits one `<text>` per word, and the checker seems
  to measure each word against the edge on its own, so any label wider than about 55 px on a vertical edge trips it.
  This was the most common noise. I "fixed" it by shortening labels, which is fine, but the warning is misleading.
- **png-cropped (medium):** raised by puml-check's *own* 2x PNG hitting PLANTUML_LIMIT_SIZE=4096. `puml-render` raises
  the limit to 16384; `puml-check --png` does not. The diagram was fine; the checker's preview was cut off (the PNG I
  looked at really was cropped on the right).
- **many-crossings (medium): "18 crossings for 16 edges"**: I count about 3 real crossings in the PNG. I suspect
  edges that cross cluster borders are being counted.

Misses (visible in the PNG, not reported):
- **An edge striking through its own label.** small: the `remote -> inet : SSL VPN 443` same-rank edge ran through
  "VPN". medium: the `HA sync` label sat on its own line. hq-perimeter: "RDP 3389 by group" was cut by its own edge.
  `edge-through-text` only seems to test *other* edges' labels and titles.
- **Invisible actor stroke** (house-style bug above).
- **Ambiguous label placement:** hq-internal "HTTPS from jump" / "RTSP to NVR only" floated between two parallel
  fan-out edges, roughly equidistant. Nothing was flagged once the labels got short.
- **Large empty bands inside packages** after the hidden-link grid-wrap (hq-internal Servers/Mgmt). Density stays
  "fine" (0.04), but a reader sees a half-empty box.
- **Semantic placement:** in small, Microsoft 365 is drawn inside the DMZ column (same rank as the DMZ). That's
  technically fine but reads as "M365 is in the DMZ". No checker could know this; the skill could say "put external
  clouds on their own rank or side".

## (d) Layout tricks that worked

- **Same-rank edge (`->` instead of `-->`) to cut a rank** (rule-of-thumb from the arrow-semantics line): `remote -> inet`
  fixed small's aspect (2.50 -> 2.00). In LR mode it stacks vertically.
- **Fold leaf nodes into labels** (ISP A/B nodes -> edge labels): removed a rank in medium (2.46 -> 2.27).
- **Link to the package instead of its members** (lever 4): this was the fix for nearly every edge-through-title
  problem: `fwpair --> dmz`, `vpn --> usr`, `corefw --> ot`, `er --> hub`, `bastion --> prod`. I moved port numbers into
  member labels (`WAF / reverse proxy :443`) so nothing was lost. Linking to a `rectangle` worked with no extra syntax.
- **Flip direction as the first try** (rule 7): helped as a diagnostic only. TB<->LR flips overshot in 3 of 3 attempts
  (small 2.50 -> 0.78; hq-perimeter 1.02 -> 1.78; cloud 0.95 -> 2.59). The fix that landed was always a graph change.
- **Hidden links between packages** (`srv -[hidden]-> ot`, `usr -[hidden]-> iot`) turned a 6-zone fan-out into 2 rows
  (hq-internal 1.74 -> 1.46). **Hidden links inside packages** (`dc -[hidden]-> file`) fixed tiny-text but made empty bands.
- **Flatten nesting:** removing the outer `cloud "Azure"` wrapper fixed cloud's height and the nested-borders info.
- Not needed: `norank`, `together`, nodesep/ranksep changes.

## (e) Syntax I had to work out outside the skill
- That `title { LineThickness 0 }` is what kills actor strokes, and that the fix only works if `actor { ... }` comes
  after it (found by bisecting the style block).
- `'` comments are not allowed inside a `<style>` block: one gives "Error in style definition: bad definition".
- Linking an edge to a `rectangle` alias (cluster edge): not documented in the skill's references; worked by trial.
- Creole table syntax in legends (`|<#FFF7ED>   | text |` for a colour swatch cell): from memory, not from the skill.
- My own tooling error worth recording: when splicing a body after the scaffold's `title` line, a naive "line
  starting with `title `" match hits the `title   { ... }` rule inside `<style>`. The resulting unclosed style block
  reports as "line 7 Syntax Error? (Assumed diagram type: sequence)", pointing at `<style>`, not at the real cause.
