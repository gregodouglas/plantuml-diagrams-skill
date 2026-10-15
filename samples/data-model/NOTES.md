# data-model/ samples: notes from a skill test run (round 2)

Eight diagrams were drawn from `samples/ticketing-input/schema.sql` (ER) and `domain.py` (class) by following `SKILL.md` literally. I loaded the skill with the Skill tool (it worked), then read `references/data-model.md` and the `er` and `class` templates. PlantUML 1.2026.8, local only. Sources are in this folder; exports (SVG, PNG, and PDF for print files) are in `out/`. Final `puml-render` ran clean on all eight files.

## (a) Results

| File | Content | Target | Size WxH | Ratio | Final status / remaining issues | Rounds (check + look) |
|---|---|---|---|---|---|---|
| `er-small.puml` | events, orders, order_items, tickets, users (5 tables, 4 edges) | 16:9 | 611x355 | 1.72 | Clean, no issues. Needed top-to-bottom plus same-rank edges (LR was 2.76, info only). | 2 + 1 |
| `er-medium.puml` | 9 tables, 14 edges | 16:9 | 1181x630 | 1.88 | Clean per checker (1 crossing). PNG: long edges wander across the page; `reviewed_by` / `requested_by` labels sit mid-edge, far from both ends. | 4 + 1 |
| `er-large.puml` | overview, 16 tables, names only, 25 edges | letter-landscape | 927x660 | 1.41 | Checker: only an info `busy` line. PNG: readable but crowded; crow's feet pile up on small name-only boxes. 2 crossings. | 4 + 1 |
| `er-large-venue.puml` | venues, venue_staff, seat_maps, sections, seats, events, price_tiers (+ users stub) | letter-landscape | 795x375 | 2.12 | Info only (fits slot unscaled). Page is wider than letter-landscape, so it fills about 45% of the height. | 2 + 1 |
| `er-large-sales.puml` | seat_holds, orders, order_items, payments, refunds, webhook_events (+ 4 stubs) | letter-landscape | 999x627 | 1.59 | Clean. Stubs are not in a top row; the two users-to-refunds edges loop over the top. `provider_event_id` tag wraps in webhook_events. Text is 9.5 px at fit. | 2 + 1 |
| `er-large-fulfilment.puml` | tickets, scans (+ order_items, users stubs) | letter-landscape | 522x227 | 2.31 | Info only; fills 22% of the slot. Only 4 tables, so a merge into another split would fit better. | 2 + 1 |
| `class-small.puml` | Order, OrderItem, Ticket, Payment, Refund + 4 status enums, 9 edges | 16:9 | 1225x616 | 1.99 | Clean, 1 crossing. Both `order` edges end at the same point on Order, so the two `1` multiplicities stack. | 6 + 3 |
| `class-medium.puml` | checkout slice: CheckoutService, HoldStore, PaymentGateway, SeatHold, Event, Seat, User, Order, OrderItem, Payment (10 classes, 14 edges) | letter portrait | 628x1063 | 0.59 | Clean at letter portrait (err -0.27). The model is a layered chain, so it is tall. 7 classes of the full model are left out and the legend says so. | 3 + 1 |

Target for `class-medium`: letter portrait, not 16:9. The services sit on top, the data they touch below, so the shape is 3 layers deep. LR gave 2.45 (warn), TB gave 0.59, and nothing in between without hacks. The full domain has 20 classes, over the 20-node hard cap once enums are drawn, so I drew the checkout slice (the services plus what they take and return).

Cardinality check, done against `schema.sql` for every edge in every ER file:
- NOT NULL FK gives `||` at the parent: user_id and event_id on orders and seat_holds, venue_id on seat_maps and events, seat_map_id on sections, section_id on seats and price_tiers, event_id on price_tiers, order_id on order_items, payments and refunds, price_tier_id on order_items, payment_id on refunds, requested_by on refunds, ticket_id and scanned_by on scans, venue_id and user_id on venue_staff.
- Nullable FK gives `|o` at the parent: orders.hold_id (`holds |o--o{ orders`), order_items.seat_id (`seats |o--o{ order_items`), refunds.reviewed_by (`users |o--o{ refunds` in the splits; `refunds }o--o| users` in er-medium and the overview).
- UNIQUE FK gives `o|` at the child: tickets.order_item_id (`order_items ||--o| tickets`, overview `tickets |o--|| order_items`).
- Child end is `o{` everywhere else. payments.provider_ref UNIQUE is not an FK, so no cardinality effect.
- Two FKs refunds to users: both edges labelled.
- Class diagrams: `Order "1" --> "0..*" OrderItem` (list), `Ticket "0..1" --> "1" OrderItem` (the UNIQUE on tickets.order_item_id), `Payment/Refund "0..*" --> "1" Order`, `Refund "0..*" --> "1" Payment`, `Order "1" --> "0..1" SeatHold` (Optional), `SeatHold "1" --> "*" Seat` (List).
- Not drawn: the overview has no webhook_events edges because the schema has none; er-small and er-medium show `hold_id`, `price_tier_id`, `seat_id` columns whose parents are outside the diagram (in er-small they carry no FK tag for that reason).

## (b) What the skill lacked or got wrong for ER and class diagrams

1. No guidance on picking a target when a model does not fit 16:9. `data-model.md` and `SKILL.md` say "decide target" but nothing says "a layered class model fits portrait letter". I picked letter portrait myself. `--target letter` exists in the checker but the class section never mentions it.
2. Row advice for ER is hard to apply. "One dash same rank, two dashes next rank" worked for er-small only after switching to top-to-bottom. For er-medium the same recipe made it worse (13 crossings, ratio 2.39). The doc has one field-test sentence but no rule for when rows help.
3. Class enums: the doc says "draw enum boxes only in a diagram about the states, and then beside their owner (`Order -> OrderStatus`)". In LR, single-dash enum edges made class-small taller (ratio 1.20 -> 1.09), not wider. The advice is direction-dependent and does not say so.
4. Multiplicity vs label collision: the doc says raise nodesep to 80-110. That moved things apart but also made the diagram taller (ratio 1.38 -> 1.30). Not a clean fix.
5. The template's example uses `<<FK>>` only for NOT NULL columns; no guidance for a nullable FK column (`hold_id`). I used no `*` plus `<<FK>>`.
6. Composite PK (venue_staff) has no pattern. I tagged both columns `<<PK>>`; the table has no FK tags, so the link to its parents is only visible from the edges.
7. Stubs "in a top row": under LR (needed for width) there is no top row. The stubs landed wherever the layout put them.
8. `puml-new er` default column style leaves the `«PK»` tag in the text, which wraps for long names (`provider_event_id : text «PK»`).
9. No guidance for an overview that exceeds the edge cap (25 edges, names only). The edge cap says 12-15; the doc says "overview with table names only" but not whether the edge cap applies.

## (c) Checker false positives and misses (report vs PNG)

- Miss: class-small, first render, checker `OK`, but the PNG showed `0..1` touching the `order_item` label and `0..*` touching the `order` label. Not detected (multiplicity text is not checked). Later renders had the same near-collisions at smaller scale.
- Miss: class-small final, `OK` with 1 crossing, but two edges converge on one point on Order and the two `1`s overlap. Not reported.
- Miss: er-medium, `OK`, but the PNG shows edges running 1000+ px across the page and two edge labels far from their ends. No long-edge check exists for ER.
- Miss: er-large (overview), crow's-foot symbols pile up on the box edges (e.g. `scans`, `refunds`). Checker only said `busy` (info).
- Fair: `aspect` info for er-large-venue / fulfilment ("fits the slot unscaled; acceptable") is accurate; the PNG is fine, it just does not fill the page.
- Fair: the `fills 22% of the slot` hint for fulfilment is useful and matches the PNG.
- No false positives seen. Crossing counts matched what I could see (1 in er-medium, 1 in class-small); er-large reports 2, I could count about 3-4 in the PNG.

## (d) Layout tricks that worked

- er-small: `top to bottom direction` plus one-dash edges for the same row (`users ||-o{ orders`, `orders }o-|| events`) and a two-dash edge down. Ratio 2.76 -> 1.72.
- Flipping an edge operand (`orders }o-|| events`) to put events on the right of orders, as the doc said. It worked.
- `hide empty members` for the name-only overview boxes (removed empty compartments; ratio 1.18 -> 1.41, boxes smaller and cleaner).
- Switching the large splits to `left to right direction` after TB gave tall narrow pages (ratio 0.74-0.88).
- class-small: a chain of same-rank edges on one row (`Refund -> Payment -> Order -> OrderItem <- Ticket`) with each enum on the row below (`-->`). Ratio 1.02 -> 1.99.
- class-medium: stop fighting the shape and change the target to portrait.
- Splitting by subject area with muted stubs for neighbours worked as described in the doc.

## (e) Syntax looked up or worked out outside the skill

- `legend right ... endlegend` (from general PlantUML knowledge; the skill says "legend" but gives no syntax). It rendered fine.
- `class X <<accent>> { ... }` for the accent class on a class diagram; the template defines `.accent` but does not show how to apply it to a class. It worked.
- `-[hidden]right-` in the er-medium attempt (copied the form from `SKILL.md` layout levers, not verified; it did nothing useful).
- `OrderItem "1" <- "0..1" Ticket`: multiplicity on a flipped arrow, worked out from the doc's `<--` hint. Each multiplicity stayed at its own class.
- Python string generation for the three ER splits (my own tooling, not PlantUML).

## (f) Compared with round 1

Fixed for me (round 1 gaps that did not bite this time):
- Same marker on every column: the `er` template now sets `classAttributeIconSize 0`, and `data-model.md` explains `*` for NOT NULL. Nullability is visible in the PNGs.
- Cardinality from the DDL: the table in `data-model.md` (NOT NULL `||`, nullable `|o`, UNIQUE `o|`) matched all my edges. No guessing needed.
- Multi-FK edges: the doc says label both and use polyline. The template is now polyline, so I did not delete ortho by hand.
- Stubs for split schemas: the doc gives the `<<muted>>` entity plus `hide empty members`. Stubs rendered as plain name boxes, not boxes with empty compartments.
- Multiplicity placement and "flip the arrowhead, not the operands": documented, and it worked.
- `interface` for plain classes: the doc now says use `class` unless the source declares one. I used `class` for the three services.
- Enums as attribute types: documented; I still drew them in class-small, as the task asked, and used the "beside their owner" advice.
- Report line now says `CLASS/ER`, so ER can be told from class.
- `ortho-with-labels` lint honouring a later polyline: not tested, I never used ortho.

Still hit:
- Crowded or colliding multiplicity labels are not reported (class-small).
- Merged or long ER edges are not reported (er-medium wanders; the doc admits merged ortho edges are not detected).
- No short notation for composite PK, or for PK plus FK on one column (venue_staff). The `«PK»` tag wraps on long column names.
- Row-building for class/ER is a single sentence. It worked for er-small and class-small, and backfired for er-medium. No rule says when.
- The borderline aspect error is still easy to miss: the limit is 0.29 and my first er-small was +0.44 but shown as info only.

New in round 2:
- Target selection for a class model that does not fit 16:9 (portrait letter); nothing in the skill covers it.
- The doc's `nodesep 80-110` fix trades collisions for height.
- The enum "same row" advice depends on direction (made LR class-small taller).
- Under LR, "stubs in a top row" has no meaning.
- No pattern for overview diagrams over the edge cap (25 edges).
