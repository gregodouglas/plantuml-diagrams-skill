# sequence/ samples: notes from a skill test run (round 2)

I followed `skills/plantuml-diagrams/SKILL.md` literally. I loaded it with the Skill tool (`plantuml-diagrams`), not by reading the file; I then read `references/sequence.md` because SKILL.md points to it. Flow per file: `puml-new sequence`, `puml-check --png`, read the PNG, `puml-render`. Input was `samples/ticketing-input/` (F1 to F5). Nothing outside `samples/sequence/` was changed. Exports are in `out/` (SVG + 2x PNG for slide files; SVG + PDF + 300 dpi PNG for print files).

## (a) Results

| File | Content | Target | Size WxH (SVG px) | Ratio | Final status / remaining issues | Rounds (check + look) |
|---|---|---|---|---|---|---|
| small.puml | F1 sign-in, 4 participants, 9 messages, 2 notes | 16:9 | 757x451 | 1.68 | OK (err -0.06). Message 3 (Fan to Identity provider) runs over the Fan web app lifeline; not reported, text is clear. | 2 check + 2 look = 4 |
| medium.puml | F2 steps 1 to 8: hold with 409 `alt`, then `POST /orders`, authorize, 3-way `alt`; 4 participants, 11 messages | 16:9 | 881x549 | 1.61 | OK (err -0.10). Only `info` lines: 3 else labels start on the first lifeline. Drops the DB row, polling and Worker steps (they are in large.puml). | 4 check + 2 look = 6 |
| webhook.puml | F3: signature, duplicate and new-event `alt` (flat, 3 branches), queue, Worker; 5 participants, 9 messages | 16:9 | 778x496 | 1.57 | OK (err -0.12). 2 `info` lines for else labels. | 3 check + 1 look = 4 |
| large.puml | F2 happy path + 3-D Secure + F3 webhook + issuing tickets; 7 participants, 15 messages, 2 `ref` | letter-landscape | 857x668 | 1.28 | OK (err -0.01). Fails at `letter` portrait (see below). Declined branch left to medium.puml. | 3 check + 1 look = 4 |
| large-refund.puml | F4; 6 participants, 7 messages, `alt` outside/approved | letter-landscape | 773x536 | 1.44 | OK (err +0.11, no warning). | 1 check + 1 look = 2 |
| large-door.puml | F5; 3 participants, 6 messages, `loop` | letter-landscape | 655x446 | 1.47 | OK (err +0.13, no warning). Loop label cut to "30 s" to satisfy the checker. | 3 check + 1 look = 4 |

**Split choice and why.** The story has 10 participants and about 45 messages. I split by flow, as sequence.md advises, not with `newpage`: the flows use different participants. large.puml is the spine (F2 to tickets, with the F3 webhook it depends on); `large-refund` is F4; `large-door` is F5. I did not make a separate F3 file in the `large-*` set because webhook.puml already is F3. large.puml points at the other two with a `ref over` row.

**Targets.** I first tried `letter` portrait for large.puml: 857x668 gave `aspect` and `tiny-text` (8 px). 7 participants cannot be tall enough at 15 messages. I chose `letter-landscape` for all three print files; they came out at 1.28 to 1.47.

**Left out because the input does not say it:** the HTTP code for a successful hold; the response to the Fan for `pending_review`; how staff approve a refund; a Database lane (the Database is not needed for the stories drawn).

## (b) What the skill lacked or got wrong for sequence diagrams

- **`else [ok]` advice produces broken output.** sequence.md says to keep else labels to 1-2 words "(`[ok]`, `[declined]`)". PlantUML adds the brackets itself. I wrote `alt [seat held]`, and the PNG showed `[` `]` treated as link markup: blue underlined "held", and "seat" dropped; same for "3-D" and `[authorized]`. Only after I removed my own brackets did it render as `[seat held]`. The skill should say: write the label without brackets.
- **The 16:9 numbers are now right, but the 4-participant case needs `Margin`.** medium.puml at default margin was 613x549 (1.12). `Margin 0 62` gave 881x549. `Margin 0 110` overshot to 1265x549 (2.30). The skill gives one data point (590 to 714 at 40); nothing says the width response is steep and non-linear (12 to 62 added 270 px at 4 participants). A short table would save a round.
- **Group-label rule is wrong in one case.** The skill says the label starts about 11 px left of the group's first lifeline. In large-door.puml the `loop` label started about 100 px left of the Staff app lifeline, because a `note over app, api` inside the loop widened the frame to the left. The label ran into the lifeline and the only fix was shortening "every 30 s while online" to "30 s". The skill does not mention that a spanning note moves the frame edge.
- **No guidance for a participant that talks to 3 neighbours.** In webhook.puml and large.puml the API talks to the Payment provider, the Database and the Job queue; one of them is never adjacent. I fixed it with a very short label ("enqueue job"). A note on this trade (short label vs reorder) is missing.
- **`loop` and `ref over` have no example** (the skill lists `ref over`, not its look). The `ref` frame draws across all lifelines in its span; fine, but unexpected.
- **`puml-new sequence` body is a payments example** that must be deleted by hand. I used `sed` to cut the body after the marker `' ---- body ----`. A `--empty` flag, or a documented marker, would help.
- **The skill says warnings carry a 1-based source line.** `message-crosses-lifeline` and `group-label-crosses-lifeline` lines had no line number in the text output (I matched them by label text).

## (c) Checker false positives and misses (report vs PNG)

- **Hit: `message-crosses-lifeline 'process_webhook'`** in webhook.puml (round 1). Correct: the enqueue label ran over the Database lifeline. Fixed by shortening.
- **Hit: `group-label-crosses-lifeline`** on `[requires 3-D Secure]` (large) and `[every 30 s while online]` (door). The PNG confirmed both. This is new coverage.
- **Partly misleading: `message-crosses-lifeline 'Secure'` and `'declined'`** in medium round 1. Those were my bracket labels turned into links; the real cause was the markup, and the report showed truncated text. Nothing said the label was being parsed as a link.
- **Miss: link markup.** First medium check also left a stray `out/medium.cmapx` (an image map for the links) beside the SVG. No issue was reported. I deleted that file.
- **Miss: arrows over a lifeline.** small.puml message 3 passes over the Fan web app lifeline. `crossings=0`, no issue. It reads fine, but `crossings=0` can be read as "none".
- **Miss: lifeline through the first characters of an else label.** The checker now reports this as `info group-label-on-lifeline`, which is accurate. In the PNG ("[all free]", "[3-D Secure]") the first character touches the lifeline but stays readable. No false positive seen.
- **No false `aspect` warnings.** The slide files reported no `info` about unscaled fit once the ratio was within 0.12. The letter-landscape files did not need the downgrade.

## (d) Layout tricks that worked

1. **`participant { Margin 0 N }` tuned by measurement.** small 12 to 70 (451 px tall: 518 to 757 wide); medium 62.
2. **Notes next to their message** instead of at the bottom (small.puml): one note beside message 2, one beside message 8. The first version had two orphan notes at the end.
3. **Flat 3-branch `alt`** in webhook.puml (bad signature / event id exists / new event) instead of a nested `alt`. One frame, one label gap.
4. **Short bracket-free else labels** (`3-D Secure`, `declined`, `all free`).
5. **Order `web, api, pay, q, w`** in large.puml: only the enqueue message crosses a lifeline, and its label is short.
6. **State transitions as `note over api`** in large-refund (void, submitted, succeeded) instead of self-messages.
7. **Landscape for a 7-participant spine.** Moving the target to `letter-landscape` removed both `aspect` and `tiny-text` with no content change.

Did not work: shortening "every 30 s while online" to "every 30 s" (still crossed); only "30 s" cleared the warning.

## (e) Syntax looked up or worked out outside the skill

- `queue "Job queue" as q` shape (the skill lists `queue` in the shape list; I used it as listed).
- `loop <label> ... end` and `alt ... else ... end`: general PlantUML knowledge; the skill names them but gives no skeleton.
- `note over A, B : text` and `note left of X : text` (one-line form).
- `ref over A, B : text`.
- `sed` to strip the template body (BSD sed `-i ''`).
- That `else`/`alt` labels get brackets added automatically: found by looking at the PNG, not from the skill (see b).

## (f) Compared with round 1

Round 1 gaps in (b):
- **Fixed for me:** 16:9 message budget (sequence.md now says about 8 messages, 50 px per message, 40 px per branch, and my numbers matched); no widening recipe (Margin recipe and "detail into notes" are now stated); activations (now "optional, skip"); self-messages (now documented, I used notes); `note over A, B` form (now documented, used in every file); nested `alt` (documented); letter portrait is hard for short flows (documented; I did not test short flows at portrait); multi-line notes (block form documented, I used `\n` one-liners and they rendered acceptably left-aligned).
- **Still hit:** group-label placement. The skill now documents the lifeline touching the label and the checker reports it, but its fix advice (`[ok]`) is wrong, and the frame-edge claim failed in large-door. Still no hint about which neighbour to sacrifice when one participant has three partners.

Round 1 gaps in (c):
- **Fixed:** group-label misses. `[new event]`-type labels are now reported (`info group-label-on-lifeline`), and crossing labels are `warn`. The `&#160;` padding trick is no longer needed.
- **Fixed:** the `aspect` false positive for short letter flows was not exercised.
- **Still hit:** arrows over a lifeline are never reported, and `crossings=0` stays ambiguous.

New in round 2: the bracket/link markup failure and the stray `.cmapx`; missing line numbers on two warning kinds; steep, non-linear `Margin` response; spanning notes moving the group frame edge.
