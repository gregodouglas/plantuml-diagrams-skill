-- Venue Ticketing: PostgreSQL 16 schema (invented sample input)

CREATE TABLE users (
  id            uuid PRIMARY KEY,
  idp_subject   text NOT NULL UNIQUE,          -- OIDC "sub"
  email         text NOT NULL,
  display_name  text,
  role          text NOT NULL CHECK (role IN ('fan', 'staff', 'admin')),
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE venues (
  id             uuid PRIMARY KEY,
  name           text NOT NULL,
  timezone       text NOT NULL,
  refund_window_hours int NOT NULL DEFAULT 48
);

CREATE TABLE venue_staff (
  venue_id  uuid NOT NULL REFERENCES venues(id),
  user_id   uuid NOT NULL REFERENCES users(id),
  PRIMARY KEY (venue_id, user_id)
);

CREATE TABLE seat_maps (
  id        uuid PRIMARY KEY,
  venue_id  uuid NOT NULL REFERENCES venues(id),
  name      text NOT NULL                       -- e.g. "Seated", "Standing"
);

CREATE TABLE sections (
  id           uuid PRIMARY KEY,
  seat_map_id  uuid NOT NULL REFERENCES seat_maps(id),
  name         text NOT NULL,
  general_admission boolean NOT NULL DEFAULT false,
  capacity     int                              -- only for general admission
);

CREATE TABLE seats (
  id          uuid PRIMARY KEY,
  section_id  uuid NOT NULL REFERENCES sections(id),
  row_label   text NOT NULL,
  number      int NOT NULL,
  UNIQUE (section_id, row_label, number)
);

CREATE TABLE events (
  id           uuid PRIMARY KEY,
  venue_id     uuid NOT NULL REFERENCES venues(id),
  seat_map_id  uuid NOT NULL REFERENCES seat_maps(id),
  title        text NOT NULL,
  starts_at    timestamptz NOT NULL,
  status       text NOT NULL CHECK (status IN ('draft', 'on_sale', 'sold_out', 'cancelled', 'completed'))
);

CREATE TABLE price_tiers (
  id          uuid PRIMARY KEY,
  event_id    uuid NOT NULL REFERENCES events(id),
  section_id  uuid NOT NULL REFERENCES sections(id),
  name        text NOT NULL,                    -- e.g. "Standard", "Concession"
  price_cents int NOT NULL,
  currency    char(3) NOT NULL
);

CREATE TABLE seat_holds (
  id          uuid PRIMARY KEY,
  event_id    uuid NOT NULL REFERENCES events(id),
  user_id     uuid NOT NULL REFERENCES users(id),
  seat_ids    uuid[] NOT NULL,                  -- mirrored in Redis with a TTL
  expires_at  timestamptz NOT NULL
);

CREATE TABLE orders (
  id           uuid PRIMARY KEY,
  user_id      uuid NOT NULL REFERENCES users(id),
  event_id     uuid NOT NULL REFERENCES events(id),
  hold_id      uuid REFERENCES seat_holds(id),
  status       text NOT NULL CHECK (status IN ('pending_payment', 'payment_failed', 'paid', 'refunded',
                                               'partially_refunded', 'disputed', 'expired')),
  total_cents  int NOT NULL,
  currency     char(3) NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
  id             uuid PRIMARY KEY,
  order_id       uuid NOT NULL REFERENCES orders(id),
  price_tier_id  uuid NOT NULL REFERENCES price_tiers(id),
  seat_id        uuid REFERENCES seats(id),     -- null for general admission
  price_cents    int NOT NULL
);

CREATE TABLE payments (
  id             uuid PRIMARY KEY,
  order_id       uuid NOT NULL REFERENCES orders(id),
  provider_ref   text NOT NULL UNIQUE,          -- payment provider's payment id
  status         text NOT NULL CHECK (status IN ('authorizing', 'requires_action', 'authorized', 'captured',
                                               'failed', 'refunded')),
  amount_cents   int NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE refunds (
  id            uuid PRIMARY KEY,
  order_id      uuid NOT NULL REFERENCES orders(id),
  payment_id    uuid NOT NULL REFERENCES payments(id),
  requested_by  uuid NOT NULL REFERENCES users(id),
  reviewed_by   uuid REFERENCES users(id),
  status        text NOT NULL CHECK (status IN ('pending_review', 'approved', 'rejected', 'submitted', 'succeeded',
                                              'failed')),
  amount_cents  int NOT NULL,
  reason        text
);

CREATE TABLE tickets (
  id             uuid PRIMARY KEY,
  order_item_id  uuid NOT NULL UNIQUE REFERENCES order_items(id),
  barcode        text NOT NULL UNIQUE,
  pdf_key        text,                          -- S3 object key, set once rendered
  status         text NOT NULL CHECK (status IN ('issued', 'used', 'void'))
);

CREATE TABLE scans (
  id          uuid PRIMARY KEY,
  ticket_id   uuid NOT NULL REFERENCES tickets(id),
  scanned_by  uuid NOT NULL REFERENCES users(id),
  device_id   text NOT NULL,
  scanned_at  timestamptz NOT NULL,
  result      text NOT NULL CHECK (result IN ('accepted', 'duplicate', 'void'))
);

CREATE TABLE webhook_events (
  provider_event_id  text PRIMARY KEY,          -- idempotency key
  type               text NOT NULL,
  payload            jsonb NOT NULL,
  received_at        timestamptz NOT NULL DEFAULT now(),
  processed_at       timestamptz
);
