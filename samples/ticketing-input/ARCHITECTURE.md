# Venue Ticketing: architecture notes

Venue Ticketing sells reserved and general-admission tickets for small music venues (100 to 2,000 seats). Fans buy
on the web; venue staff manage events and scan tickets at the door.

## People

- **Fan**: browses events, buys tickets, receives tickets by email, can request a refund.
- **Venue staff**: create events, set seat maps and prices, run the box office, scan tickets at the door.
- **Platform admin**: onboards venues, handles disputes, issues manual refunds.

## External systems

- **Identity provider** (OIDC): signs in fans and staff. Authorization code flow with PKCE. The platform keeps no
  passwords.
- **Payment provider**: card payments. Authorize, capture, refund. Sends signed webhooks for asynchronous results
  (3-D Secure outcomes, disputes, refunds).
- **Email service**: transactional email (order confirmation with ticket PDFs, refund notices).

## Containers

| Container | Technology | Responsibility |
|---|---|---|
| Fan web app | single-page app (TypeScript), served from the CDN | browse events, seat picker, checkout, my tickets |
| Staff app | single-page app (TypeScript), installable PWA | event setup, box office, door scanning; works offline at the door and syncs scans later |
| Ticketing API | REST, Python (FastAPI), container | all business logic: catalogue, seat holds, orders, payments, tickets, refunds, scans |
| Worker | Python, container | async jobs from the queue: render ticket PDFs, send email, process payment webhooks, expire holds |
| Database | PostgreSQL 16 | system of record (see `schema.sql`) |
| Seat-hold cache | Redis | short-lived seat holds (10-minute TTL) so two fans cannot check out the same seat |
| Job queue | SQS, with a dead-letter queue | decouples the API from slow work |
| Ticket store | S3 bucket | rendered ticket PDFs, served by presigned URL |

## Key relationships

- Both apps call the Ticketing API over HTTPS (JSON). Neither talks to the database directly.
- The API reads and writes the Database, places and releases holds in the Seat-hold cache, and enqueues jobs on the
  Job queue.
- The Worker consumes the Job queue, reads and writes the Database, writes PDFs to the Ticket store, and calls the
  Email service.
- The API calls the Payment provider to authorize, capture and refund. The Payment provider sends webhooks to the
  API, which verifies the signature and enqueues them for the Worker.
- Both apps redirect to the Identity provider to sign in; the API validates the access tokens it issues (JWKS).

## API internals (components of the Ticketing API)

| Component | Responsibility | Uses |
|---|---|---|
| Auth middleware | validates the bearer token against the IdP's JWKS, maps roles (fan, staff, admin) | Identity provider |
| Catalogue | venues, events, seat maps, price tiers | Database |
| Holds | place, extend and release seat holds | Seat-hold cache |
| Checkout | create orders from holds, start payment | Holds, Payments, Database |
| Payments | provider client: authorize, capture, refund; webhook signature check | Payment provider, Job queue |
| Ticketing | issue and void tickets, enqueue PDF rendering | Database, Job queue |
| Door | accept scan batches from the staff app, detect duplicates | Database |
| Refunds | refund requests and approvals | Payments, Ticketing, Database |
