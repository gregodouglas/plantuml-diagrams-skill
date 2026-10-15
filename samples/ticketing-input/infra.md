# Venue Ticketing: AWS deployment

One AWS account per environment (staging, production); production is described here. Region: one, two Availability
Zones (AZ a and AZ b). Infrastructure as code; nothing is clicked together by hand.

## Edge

- **Route 53** hosts the public zone: `tickets.example.com` (fan app), `staff.example.com` (staff app),
  `api.example.com` (API).
- **CloudFront** serves both single-page apps from an **S3 bucket** (static assets, private, origin access control)
  and forwards `api.example.com` to the Application Load Balancer.
- **AWS WAF** is attached to CloudFront: managed common rules plus a rate limit on `POST /orders` and `POST /holds`.
- **ACM** certificates on CloudFront and the load balancer.

## Network

- **VPC** with, in each AZ, one public subnet and one private subnet.
- **Public subnets**: the Application Load Balancer (spans both AZs) and one **NAT gateway** per AZ.
- **Private subnets**: ECS tasks, RDS, ElastiCache. No public IPs.
- Outbound calls from the private subnets (Payment provider, Identity provider JWKS, Email service if not SES) go out
  through the NAT gateway of the same AZ.
- **VPC endpoints** for S3, SQS, Secrets Manager and CloudWatch Logs, so that traffic to them stays off the NAT.

## Compute (ECS on Fargate)

- **api** service: 2 to 6 tasks across both AZs, behind the load balancer's target group, autoscaled on CPU and request
  count.
- **worker** service: 1 to 4 tasks across both AZs, autoscaled on the SQS queue depth. Not reachable from the load
  balancer.
- Images come from **ECR**. Task secrets (database password, payment provider API key, webhook signing secret) come
  from **Secrets Manager** at task start.

## Data

- **RDS for PostgreSQL 16**, Multi-AZ: primary in AZ a, synchronous standby in AZ b. Automated backups 14 days.
- **ElastiCache for Redis**: primary in AZ a, replica in AZ b, automatic failover. Holds only seat holds (safe to
  lose: holds are also in Postgres).
- **SQS** `jobs` queue with a dead-letter queue (`jobs-dlq`) after 5 receives.
- **S3** `tickets` bucket for ticket PDFs: private, SSE-KMS, presigned GET URLs valid 24 hours, lifecycle to delete
  365 days after the event.

## Email and observability

- **Amazon SES** sends transactional email from the worker (the "Email service" in the architecture notes).
- **CloudWatch**: logs from both services, metrics, alarms (5xx rate, queue age, DLQ not empty) to an SNS topic that
  pages the on-call engineer.

## External, outside AWS

- **Identity provider** (OIDC) and **Payment provider**: reached over HTTPS through the NAT gateways; the Payment
  provider's webhooks come in through CloudFront and the load balancer like any API call.
