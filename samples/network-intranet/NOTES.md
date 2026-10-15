# network-intranet: field-test notes for the plantuml-diagrams skill

Domain: internal LAN / VLAN documentation (core stack, distribution/access, VLANs + subnets, wireless, servers,
inter-VLAN firewall rules). Scaffolded with `scripts/puml-new deployment`, checked with `scripts/puml-check --png`,
exported with `scripts/puml-render` (slide preset for small/medium, print preset for large* and nwdiag). The
general skill findings (actor stroke bug, detached-label false positives, own-label strike-through misses,
png-cropped in check) are in `../network-boundary/NOTES.md`. This file covers what was different here.

## (a) Results

| File | Target | Size (SVG px) | Ratio | Issues on first check | Final status | Rounds (+look) |
|---|---|---|---|---|---|---|
| small.puml | 16:9 | 991x611 | 1.62 | none | OK | 0 |
| medium.puml | 16:9 | 1366x918 | 1.49 | none | OK | 0 (+1: core stack drawn upside down) |
| nwdiag-medium.puml | letter (see below) | 689x741 | 0.93 | ERROR with `@startuml`; then aspect vs 16:9 | OK vs `letter`; WARN aspect vs 16:9 | 2 |
| large.puml (overview, 11 nodes) | letter-landscape | 816x817 | 1.00 | aspect 0.79 | OK | 3 |
| large-switching.puml | letter-landscape | 947x688 | 1.38 | none | OK | 0 |
| large-vlans.puml | letter-landscape | 728x550 | 1.32 | aspect 2.00, detached-label x2 (FP) | OK | 2 |
| large-wireless.puml | letter-landscape | 830x601 | 1.38 | edge-through-text (SSIDs title) | OK | 1 |
| large-servers.puml | letter-landscape | 1070x679 | 1.58 | aspect 2.28, edge-through-text, detached-label (FP) | OK | 3 (+2) |

All OK except `nwdiag-medium.puml` against 16:9. nwdiag draws one horizontal bus per network, stacked vertically,
and has no direction control. Seven VLANs give a portrait shape whatever you do (0.78 -> 0.93 after trimming). It
passes `--target letter`, so I'm delivering it as a portrait/print alternative. To reach 16:9 you would have to split
it into two nwdiag files of 3-4 VLANs each. I didn't, because the deployment-style `medium.puml` already covers the
slide case.

### Why the large size was split
The campus inventory came to ~40 nodes (2 core, 4 distribution, 7 access, 20 APs as 2 groups, WLC, 5 SSID/VLAN
targets, 5 servers, 3 hypervisors, SAN, backup) across 6 VLANs + storage/backup VLANs: far over 20 nodes / 7 groups.
- `large.puml`: overview (11 nodes: firewall, core, DC/MDF zones, two buildings as dist -> access -> APs) plus a VLAN/subnet table in the legend.
- `large-switching.puml`: physical fabric: core stack, MLAG distribution pairs, 7 access switches.
- `large-vlans.puml`: the inter-VLAN routing/firewall policy. Every edge is one allow rule; a note says everything else is denied.
- `large-wireless.puml`: APs -> WLC (CAPWAP), SSIDs -> VLANs, 802.1X to NPS.
- `large-servers.puml`: VLAN 10 VMs, hypervisor cluster, non-routed iSCSI VLAN 11, backup VLAN 12.

## (b) What the skill was unclear about, missing, or wrong for this domain

1. **Physical vs logical in one picture.** The skill has no guidance on the classic LAN-diagram mistake of mixing
   switch topology (physical) and VLAN membership (logical) in one diagram. In medium I mixed them deliberately
   (switches as nodes, VLANs as rectangles, trunk VLAN lists on the edges) and it reads OK. For large, the split by
   *layer* (fabric / VLAN policy / wireless / servers) worked much better than splitting by building. A sentence in
   `choosing-and-design.md` ("split network docs by layer: physical, logical, policy") would help.
2. **Firewall rules belong in a table, but tables in a legend are cramped.** The skill does say "prefer a table for
   mappings/matrices". I put the medium rule matrix in a `legend` creole table: it works, but it renders at a smaller
   effective size with heavy black borders. For large, I drew rules as edges between VLAN nodes (`large-vlans.puml`),
   which reads much better as a picture. No guidance on when a rule set should be edges and when a table.
3. **Subnet labels:** no guidance. Two-line titles (`"VLAN 20 Workstations\n10.10.20.0/24"`) on rectangles and nodes
   work well and never tripped a check. Host octets as a second line in the node label (`"DC1\n.10"`) are cleaner than
   edge labels.
4. **nwdiag is mentioned once** (`choosing-and-design.md`: "Not covered by templates but valid: ... network (nwdiag)").
   There's no template, and no warning that the `@startuml` form is now rejected, that network names must be
   identifiers, that the house `<style>` only partly applies, or that the layout can't be steered. See (e).
5. **Rule 2 says declaration order sets left-to-right order within a layer.** In `left to right direction`, a flat
   same-rank pair (`c1 - c2`) inside a rectangle came out reversed: CORE-2 above CORE-1, and NMS above WLC even though
   WLC was declared first. Swapping the declaration order fixed it. The transposition note in SKILL.md covers arrow
   keywords, not declaration order under LR.

## (c) Checker false positives and misses (report vs PNG)

- **nwdiag: the geometry checks are blind.** The report shows `NWDIAG ... nodes=0 edges=0`. In the first render, every
  address label (".1", "203.0.113.2", "DHCP", ".50-.59") was struck through by the vertical link line. That is
  nwdiag's default placement of `address`, and the checker reported nothing about it. Only the aspect check works. I
  fixed it by hand by moving addresses into `description` (two-line node labels).
- **nwdiag: the aspect hint is wrong for the type.** It said "use left to right direction (chains), shorten --> to ->,
  lower ranksep". None of those exist in nwdiag.
- **detached-label false positives again** (trailing words of "SIP TLS 5061, RTP", "IPP 631 (print srv)", "backup API
  443"). Same per-word cause as in the boundary notes.
- **Miss:** large-servers "2x25G LACP" sits about 45 px off its edge, beside an empty area. It reads as floating but is
  under the threshold. Meanwhile the snug labels above get flagged. The metric probably wants to measure the whole
  label's bounding box, not single words.
- **Miss:** large-servers: the `v10 -[hidden]-> hvc` "stack" only pushed the cluster down a rank. It did not stack under
  VLAN 10. The checker can't know what was intended, so this is fine, but SKILL.md lever 5 ("`A -[hidden]-> B` to
  stack") overpromises when A and B are packages of very different widths.

## (d) Layout tricks that worked

- **Flip to LR for a "sources -> targets" policy graph:** large-vlans went from 2.00 (TB, four source VLANs in a row) to
  1.32 (LR, sources stacked on the left). This was the one case where flipping direction was the whole fix, as rule 7
  predicts.
- **Same-rank edge to cut a rank:** `inet -> fw` in the overview (TB 0.79 -> 1.00). Doing it also for `access -> APs`
  overshot to 1.78, so one same-rank edge was the right amount.
- **Link to the package:** `wlc --> ssids : broadcasts` removed the SSID-title crossing; `hvc --> v11` removed the
  storage-title crossing; `cs --> dap` (core stack -> distribution-pair rectangle) kept the switch fabric to 13 edges
  and passed first time.
- **Nested rectangles for MLAG/stack pairs** (`rectangle "Dist A pair (MLAG)" { da1; da2 }` + `da1 - da2`) read
  clearly and checked clean.
- **Grid-wrap with hidden links inside a package** (`dc1 -[hidden]-> file`) roughly halved large-servers' width.
- Not needed: `norank`, `together`, spacing skinparams.

## (e) Syntax I had to work out outside the skill (nwdiag)

- **`@startuml` + `nwdiag { }` fails in 1.2026.8:** "This looks like a network diagram. Please use @startnwdiag instead
  of @startuml." `puml-check` relays that message correctly for a bare file (exit 2, `ERROR line 8`). But with the house
  `<style>` and a `title` before the block, PlantUML only says "Syntax Error? (Assumed diagram type: sequence)" and the
  hint is lost. `puml-check --lint-only` passes the `@startuml` form as OK, so the lint has no rule for it.
- **Delivered form:** `@startnwdiag` ... `@endnwdiag`. `puml-check` and `puml-render` both handle it: they report type
  NWDIAG, measure it, and export SVG/PNG/PDF fine.
- **Network names must be identifiers:** `network "VLAN 10 Servers" { }` is a syntax error. Use
  `network v10 { description = "VLAN 10 Servers" ... }`.
- **Gotcha:** a comment line containing the literal text `@startuml` inside an `@startnwdiag` file broke the parse
  ("Syntax Error?" at line 2). I reworded the comment.
- **Style:** a `<style>` with `root { FontName ... }` and `title { LineThickness 0 }` applies (font and title box border).
  I didn't try the full house style: nwdiag ignores `element`/`arrow`, and `puml-new` has no nwdiag type to scaffold from.
- `color = "#hex"` on a network colours the bus. A host listed in two networks (`ps;` in VLAN 40) draws a second link,
  which is good for multi-homed servers and the firewall.
