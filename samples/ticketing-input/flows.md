# Venue Ticketing: flows

Step-by-step behaviour of the main flows. Names match `ARCHITECTURE.md`; endpoints are on the Ticketing API.

## F1. Fan sign-in (OIDC authorization code + PKCE)

1. Fan clicks "Sign in" in the Fan web app.
2. The web app creates a PKCE verifier and challenge, and redirects the browser to the Identity provider's
   `/authorize` with the challenge.
3. The Fan authenticates at the Identity provider (password, passkey or social login; not our concern).
4. The Identity provider redirects back to the web app's callback with an authorization `code`.
5. The web app exchanges the code plus the PKCE verifier at the Identity provider's `/token` and receives an access
   token and an ID token.
6. The web app calls `GET /me` on the Ticketing API with the bearer token.
7. The API's Auth middleware validates the token signature against the Identity provider's JWKS (cached for 1 hour;
   fetched on a cache miss) and checks audience and expiry.
8. On first sign-in the API creates the `users` row (upsert by IdP subject). The API returns the profile.

## F2. Checkout (reserved seats, card payment)

1. Fan picks seats in the seat picker. The web app calls `POST /events/{id}/holds` with the seat ids.
2. The API asks the Seat-hold cache to `SET NX` each seat with a 10-minute TTL.
   - **If any seat is already held**: the API releases the seats it just took and returns `409 seats_taken`; the web
     app refreshes the seat map. (End of flow.)
3. The API records a `seat_holds` row and returns the hold id and its expiry.
4. Fan reviews and pays: the web app calls `POST /orders` with the hold id.
5. The API creates the order (`status = pending_payment`) and calls the Payment provider to **authorize** the amount.
6. The Payment provider answers one of three ways:
   - **Authorized**: continue at step 7.
   - **Requires 3-D Secure**: the API returns `202` with a challenge URL; the web app shows the challenge; the Fan
     completes it with their bank; the Payment provider later sends a `payment.authorized` webhook (see F3), and the
     web app polls `GET /orders/{id}` until the order is `paid`.
   - **Declined**: the API marks the order `payment_failed`, keeps the hold until it expires, and returns `402`.
7. The API **captures** the payment, marks the order `paid`, converts the hold into `order_items`, releases the
   Redis keys, and enqueues an `issue_tickets` job.
8. The API returns `201` with the order. The web app shows "Tickets on their way".
9. The Worker takes the `issue_tickets` job, creates one `tickets` row per seat, renders each ticket PDF to the Ticket
   store, and asks the Email service to send the confirmation with links.

## F3. Payment webhook

1. The Payment provider sends `POST /webhooks/payments` with a signed event.
2. The API verifies the signature. Bad signature: `400`, nothing stored.
3. The API inserts the event into `webhook_events` keyed by the provider's event id. If it already exists (a
   redelivery), the API returns `200` and stops (idempotency).
4. The API enqueues a `process_webhook` job and returns `200` immediately.
5. The Worker processes it by type: `payment.authorized` captures and continues F2 from step 7; `payment.failed`
   marks the order `payment_failed`; `charge.refunded` completes a refund (F4); `dispute.opened` flags the order
   `disputed` for an admin.

## F4. Refund

1. Fan requests a refund for an order in "My tickets": `POST /orders/{id}/refunds` with a reason.
2. The API checks the venue's refund policy (allowed until 48 hours before the event). Outside the window: the
   request is stored as `pending_review` for venue staff.
3. Approved (automatically inside the window, or by staff): the API voids the tickets, calls the Payment provider to
   refund, and marks the refund `submitted`.
4. The Payment provider sends `charge.refunded`; the Worker marks the refund `succeeded`, the order `refunded`, and
   emails the Fan.

## F5. Door scanning (offline-first)

1. Before doors open, the Staff app downloads the event's ticket list (`GET /events/{id}/door-list`): ticket ids,
   barcodes, current status.
2. Staff scan each ticket's barcode. The app checks it against the local list and shows green (valid), red (void or
   unknown) or amber (already scanned on this device).
3. Every 30 seconds while online, the app posts a batch of scans (`POST /events/{id}/scans`).
4. The API's Door component records each scan, marks the ticket `used`, and returns any conflicts: tickets already
   scanned on another device. The app shows conflicts to the staff member.
