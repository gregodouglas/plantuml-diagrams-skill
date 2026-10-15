# Worked example: the same 12-node, 14-edge system before and after the skill's rules

`before.puml` is what an LLM typically emits: long sentence labels on every edge, default styling, no direction decision.
`after.puml` applies the rules: the house style from `puml-new`, short verb-first labels, `polyline`, elements declared in
reading order, two cross-edges marked `[norank]`, and two same-rank links (`lb -> gw`, `orders -> pay`) that lay Edge and
Services out as rows. The direction was chosen by measuring: left-to-right gave 1.38:1 with 9 crossings and a title crossing,
top-to-bottom gave 1.82:1 (target 1.78) with no issues. Edge crossings went from 8 to 3.

`check-report.txt` is the `puml-check --target 16:9` output for both; `out/` holds the slide renders (SVG + 2x PNG).
