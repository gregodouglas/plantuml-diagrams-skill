"""Venue Ticketing domain model (invented sample input).

Plain classes plus the state machines the API enforces. Persistence lives in repositories (not shown); the
`TRANSITIONS` tables are the single source of truth for which status changes are legal.
"""
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import List, Optional
from uuid import UUID


@dataclass(frozen=True)
class Money:
    cents: int
    currency: str  # ISO 4217


class Role(Enum):
    FAN = "fan"
    STAFF = "staff"
    ADMIN = "admin"


@dataclass
class User:
    id: UUID
    idp_subject: str
    email: str
    role: Role


@dataclass
class Venue:
    id: UUID
    name: str
    timezone: str
    refund_window_hours: int = 48


@dataclass
class Section:
    id: UUID
    name: str
    general_admission: bool
    capacity: Optional[int] = None


@dataclass
class Seat:
    id: UUID
    section: Section
    row_label: str
    number: int


@dataclass
class SeatMap:
    id: UUID
    venue: Venue
    sections: List[Section] = field(default_factory=list)


@dataclass
class PriceTier:
    id: UUID
    section: Section
    name: str
    price: Money


# ---- Event lifecycle -------------------------------------------------------------------------------------
class EventStatus(Enum):
    DRAFT = "draft"
    ON_SALE = "on_sale"
    SOLD_OUT = "sold_out"
    CANCELLED = "cancelled"
    COMPLETED = "completed"


EVENT_TRANSITIONS = {
    # (from, to): trigger
    (EventStatus.DRAFT, EventStatus.ON_SALE): "staff publishes",
    (EventStatus.ON_SALE, EventStatus.SOLD_OUT): "last seat sold",
    (EventStatus.SOLD_OUT, EventStatus.ON_SALE): "refund frees a seat",
    (EventStatus.DRAFT, EventStatus.CANCELLED): "staff cancels",
    (EventStatus.ON_SALE, EventStatus.CANCELLED): "staff cancels (all orders refunded)",
    (EventStatus.SOLD_OUT, EventStatus.CANCELLED): "staff cancels (all orders refunded)",
    (EventStatus.ON_SALE, EventStatus.COMPLETED): "event end time passes",
    (EventStatus.SOLD_OUT, EventStatus.COMPLETED): "event end time passes",
}


@dataclass
class Event:
    id: UUID
    venue: Venue
    seat_map: SeatMap
    title: str
    starts_at: datetime
    status: EventStatus = EventStatus.DRAFT
    price_tiers: List[PriceTier] = field(default_factory=list)

    def publish(self) -> None: ...
    def cancel(self) -> None: ...


# ---- Seat holds ------------------------------------------------------------------------------------------
@dataclass
class SeatHold:
    id: UUID
    event: Event
    user: User
    seats: List[Seat]
    expires_at: datetime  # 10 minutes after creation; extendable once by 5 minutes

    def is_expired(self, now: datetime) -> bool: ...


# ---- Orders ------------------------------------------------------------------------------------------------
class OrderStatus(Enum):
    PENDING_PAYMENT = "pending_payment"
    PAYMENT_FAILED = "payment_failed"
    PAID = "paid"
    PARTIALLY_REFUNDED = "partially_refunded"
    REFUNDED = "refunded"
    DISPUTED = "disputed"
    EXPIRED = "expired"


ORDER_TRANSITIONS = {
    (OrderStatus.PENDING_PAYMENT, OrderStatus.PAID): "payment captured",
    (OrderStatus.PENDING_PAYMENT, OrderStatus.PAYMENT_FAILED): "authorization declined or 3DS failed",
    (OrderStatus.PAYMENT_FAILED, OrderStatus.PENDING_PAYMENT): "fan retries with another card (hold still valid)",
    (OrderStatus.PAYMENT_FAILED, OrderStatus.EXPIRED): "hold expires",
    (OrderStatus.PENDING_PAYMENT, OrderStatus.EXPIRED): "hold expires before payment completes",
    (OrderStatus.PAID, OrderStatus.PARTIALLY_REFUNDED): "refund of some tickets succeeds",
    (OrderStatus.PARTIALLY_REFUNDED, OrderStatus.REFUNDED): "refund of remaining tickets succeeds",
    (OrderStatus.PAID, OrderStatus.REFUNDED): "full refund succeeds",
    (OrderStatus.PAID, OrderStatus.DISPUTED): "dispute.opened webhook",
    (OrderStatus.PARTIALLY_REFUNDED, OrderStatus.DISPUTED): "dispute.opened webhook",
    (OrderStatus.DISPUTED, OrderStatus.PAID): "dispute won",
    (OrderStatus.DISPUTED, OrderStatus.REFUNDED): "dispute lost (funds returned)",
}
# Final states: EXPIRED, REFUNDED.


@dataclass
class OrderItem:
    id: UUID
    price_tier: PriceTier
    seat: Optional[Seat]  # None for general admission
    price: Money


@dataclass
class Order:
    id: UUID
    user: User
    event: Event
    hold: Optional[SeatHold]
    items: List[OrderItem] = field(default_factory=list)
    status: OrderStatus = OrderStatus.PENDING_PAYMENT

    def total(self) -> Money: ...
    def mark_paid(self) -> None: ...
    def request_refund(self, items: List[OrderItem], reason: str) -> "Refund": ...


# ---- Payments ----------------------------------------------------------------------------------------------
class PaymentStatus(Enum):
    AUTHORIZING = "authorizing"
    REQUIRES_ACTION = "requires_action"  # 3-D Secure challenge pending
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    FAILED = "failed"
    REFUNDED = "refunded"


PAYMENT_TRANSITIONS = {
    (PaymentStatus.AUTHORIZING, PaymentStatus.AUTHORIZED): "provider approves",
    (PaymentStatus.AUTHORIZING, PaymentStatus.REQUIRES_ACTION): "provider requests 3DS",
    (PaymentStatus.AUTHORIZING, PaymentStatus.FAILED): "provider declines",
    (PaymentStatus.REQUIRES_ACTION, PaymentStatus.AUTHORIZED): "payment.authorized webhook",
    (PaymentStatus.REQUIRES_ACTION, PaymentStatus.FAILED): "payment.failed webhook or 15 min timeout",
    (PaymentStatus.AUTHORIZED, PaymentStatus.CAPTURED): "API captures",
    (PaymentStatus.CAPTURED, PaymentStatus.REFUNDED): "charge.refunded webhook (full)",
}


@dataclass
class Payment:
    id: UUID
    order: Order
    provider_ref: str
    amount: Money
    status: PaymentStatus = PaymentStatus.AUTHORIZING


# ---- Refunds -----------------------------------------------------------------------------------------------
class RefundStatus(Enum):
    PENDING_REVIEW = "pending_review"
    APPROVED = "approved"
    REJECTED = "rejected"
    SUBMITTED = "submitted"
    SUCCEEDED = "succeeded"
    FAILED = "failed"


REFUND_TRANSITIONS = {
    (RefundStatus.PENDING_REVIEW, RefundStatus.APPROVED): "staff approves",
    (RefundStatus.PENDING_REVIEW, RefundStatus.REJECTED): "staff rejects",
    (RefundStatus.APPROVED, RefundStatus.SUBMITTED): "API calls provider refund",
    (RefundStatus.SUBMITTED, RefundStatus.SUCCEEDED): "charge.refunded webhook",
    (RefundStatus.SUBMITTED, RefundStatus.FAILED): "provider rejects refund",
    (RefundStatus.FAILED, RefundStatus.SUBMITTED): "admin retries",
}
# A request inside the venue's refund window is created directly as APPROVED (no review).


@dataclass
class Refund:
    id: UUID
    order: Order
    payment: Payment
    requested_by: User
    amount: Money
    reason: str
    status: RefundStatus = RefundStatus.PENDING_REVIEW


# ---- Tickets and scans -------------------------------------------------------------------------------------
class TicketStatus(Enum):
    ISSUED = "issued"
    USED = "used"
    VOID = "void"


TICKET_TRANSITIONS = {
    (TicketStatus.ISSUED, TicketStatus.USED): "accepted scan at the door",
    (TicketStatus.ISSUED, TicketStatus.VOID): "refund approved or event cancelled",
}
# USED and VOID are final. A scan of a USED ticket is recorded as a duplicate; of a VOID ticket, as void.


@dataclass
class Ticket:
    id: UUID
    order_item: OrderItem
    barcode: str
    pdf_key: Optional[str] = None
    status: TicketStatus = TicketStatus.ISSUED

    def scan(self, by: User, device_id: str, at: datetime) -> "Scan": ...


class ScanResult(Enum):
    ACCEPTED = "accepted"
    DUPLICATE = "duplicate"
    VOID = "void"


@dataclass
class Scan:
    id: UUID
    ticket: Ticket
    scanned_by: User
    device_id: str
    scanned_at: datetime
    result: ScanResult


# ---- Services (interfaces the API components implement) ---------------------------------------------------
class PaymentGateway:
    """Adapter over the payment provider's API."""
    def authorize(self, order: Order, amount: Money) -> Payment: ...
    def capture(self, payment: Payment) -> None: ...
    def refund(self, payment: Payment, amount: Money) -> None: ...
    def verify_webhook(self, body: bytes, signature: str) -> bool: ...


class HoldStore:
    """Seat holds in Redis (SET NX with TTL)."""
    def place(self, event: Event, seats: List[Seat], user: User) -> SeatHold: ...
    def release(self, hold: SeatHold) -> None: ...


class CheckoutService:
    def __init__(self, holds: HoldStore, payments: PaymentGateway): ...
    def create_order(self, hold: SeatHold) -> Order: ...
