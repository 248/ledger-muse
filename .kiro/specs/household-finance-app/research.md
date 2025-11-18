# Research & Design Decisions

---
**Purpose**: Capture discovery findings, architectural investigations, and rationale that inform the technical design.

**Usage**:
- Log research activities and outcomes during the discovery phase.
- Document design decision trade-offs that are too detailed for `design.md`.
- Provide references and evidence for future audits or reuse.
---

## Summary
- **Feature**: `household-finance-app`
- **Discovery Scope**: New Feature (greenfield)
- **Key Findings**:
  - Google Cloud Identity Platform integrates well with Next.js via NextAuth.js/Auth.js for 2025
  - Go Echo framework provides robust middleware and structure for Cloud Run deployments
  - Firestore-to-PostgreSQL migration requires JSONB-based approach initially for schema flexibility
  - Cloud Vision API optimized for receipt OCR with pre-processing recommendations
  - Pub/Sub for event-driven architecture, Cloud Tasks for explicit task control
  - Hexagonal Architecture recommended for domain isolation and future scalability

## Research Log

### Authentication & Identity Platform Integration
- **Context**: Need to implement secure authentication with Google Cloud Identity Platform for Next.js frontend
- **Sources Consulted**:
  - [Next.js と Auth.js で実装する Google Cloud Identity Platform 認証](https://tagbangers.co.jp/en/blog/posts/2025/02/gcip-with-nextjs-authjs)
  - [Official Firebase Authentication: Verify ID Tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens)
  - [NextAuth.js Google Authentication Guide](https://medium.com/@rasimcetin87/implementing-google-authentication-in-next-js-a-comprehensive-guide-5ea661526d9b)
- **Findings**:
  - NextAuth.js (Auth.js) is the standard approach for integrating Identity Platform with Next.js in 2025
  - Built-in TypeScript support and session management via JWT
  - Custom backend integration pattern: Use Google ID token for authentication, create custom authorization tokens for backend
  - Security: HTTPS required in production, store AuthToken in httpOnly cookies, validate on every request
  - Session management: Default JWT storage, expose SessionProvider at app root
- **Implications**:
  - Frontend: NextAuth.js with Google Provider configured for Identity Platform
  - Backend: JWT validation middleware using Firebase Admin SDK or third-party JWT library
  - Token flow: Frontend obtains ID token → sends to backend in Authorization header → backend validates and extracts user claims

### Go Echo Framework & Cloud Run Deployment
- **Context**: Backend API implementation and containerized deployment to Cloud Run
- **Sources Consulted**:
  - [Echo Framework Official Documentation](https://echo.labstack.com/)
  - [Google Cloud Run Quickstart: Go](https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-go-service)
  - [Go Echo + Cloud Run Example](https://github.com/onori/cloud-run-go-echo)
  - [Echo JWT Middleware](https://echo.labstack.com/docs/middleware/jwt)
- **Findings**:
  - Echo framework adoption: 16% of Go developers in 2025, suitable for medium-to-large API projects
  - Echo provides structured middleware pipeline (logging, CORS, JWT validation, error recovery)
  - Cloud Run deployment: Containerized via Dockerfile using distroless base image for security
  - Deployment parameters: `--platform managed`, `--region`, `--allow-unauthenticated` (for public endpoints with auth middleware), `--max-instances` for cost control
  - Firebase JWT middleware packages available: `github.com/reedom/echo-middleware-firebasejwt` and `github.com/mondora/firebase-auth-echo-middleware`
- **Implications**:
  - Use Echo's middleware chain: Logger → CORS → JWT → Error Recovery → Application Routes
  - Containerization: Multi-stage Dockerfile (build stage with Go SDK, runtime stage with distroless)
  - JWT validation: Use echo-middleware-firebasejwt for automatic token verification
  - Cloud Run autoscaling: Configure min/max instances based on cost targets

### Database Strategy: Firestore → PostgreSQL Migration
- **Context**: Start with Firestore for learning/low-cost, plan migration path to Cloud SQL PostgreSQL for relational features
- **Sources Consulted**:
  - [Migrate data from Firestore to Cloud SQL](https://ice-panda.medium.com/migrate-data-from-firestore-to-cloud-sql-on-google-cloud-c89b8feb1d70)
  - [Functionally migrating from Firestore to PostgreSQL](https://medium.com/@ValentinMouret/functionally-migrating-from-firestore-to-postgresql-64947b5dff0d)
  - [Firebase Data Connect](https://firebase.google.com/docs/data-connect)
  - [Supabase Firestore Migration Guide](https://supabase.com/docs/guides/platform/migrating-to-supabase/firestore-data)
- **Findings**:
  - PostgreSQL JSONB support bridges NoSQL→relational paradigm: store documents in 2-column structure (ID, document) initially
  - Progressive normalization: Extract ID fields first (data integrity), then extract filtered fields (performance), finally full relational schema
  - PostgreSQL features: GIN indexes on JSONB columns, advanced JSON querying, ACID transactions
  - Firebase Data Connect: New service (2024-2025) providing managed PostgreSQL with GraphQL layer
  - Migration tools: Google Cloud Database Migration Service, custom scripts for Firestore→PostgreSQL export
- **Implications**:
  - Initial data model: Firestore collections with clear document structure
  - Design constraint: Use normalized-style references (documentId) even in Firestore to ease migration
  - Migration phases: 1) JSONB storage in PostgreSQL, 2) Extract critical fields to columns, 3) Full relational normalization
  - Schema evolution: Define entities/relationships now, implement in Firestore, migrate structure to PostgreSQL later

### OCR with Cloud Vision API
- **Context**: Automate receipt data extraction (amount, date, merchant) from uploaded images
- **Sources Consulted**:
  - [Cloud Vision API OCR Documentation](https://cloud.google.com/vision/docs/ocr)
  - [Receipt OCR Best Practices](https://www.leanx.eu/tutorials/use-google-cloud-vision-api-to-process-invoices-and-receipts)
  - [Invoice Processing with OCR](https://blog.futuresmart.ai/invoice-processing-with-ocr-using-google-vision-api-and-gpt-4)
  - [2025 OCR Benchmark: Veryfi vs Google vs Mindee](https://www.veryfi.com/ai-insights/invoice-ocr-competitors-veryfi/)
- **Findings**:
  - TEXT_DETECTION: General text extraction with bounding boxes, suitable for receipts
  - DOCUMENT_TEXT_DETECTION: Optimized for dense text, provides hierarchical structure (page→block→paragraph→word)
  - Pre-processing recommendations: Straight edges, high contrast, minimal noise (API performs internal deskewing)
  - Supported formats: JPEG, PNG (non-lossy formats preferred)
  - File size: Recommended under 10MB
  - Language detection: Automatic detection works best for Latin-based languages (omit language hints)
  - Confidence scores: API returns confidence levels for extracted text
  - Performance target: Processing typically completes within seconds (30s target is conservative)
- **Implications**:
  - Use DOCUMENT_TEXT_DETECTION for receipts to get structured text blocks
  - Client-side: Basic image validation (format, size) before upload
  - Server-side: Cloud Vision API call → parse JSON response → extract amount (look for currency symbols + numbers), date (pattern matching), merchant (top text blocks)
  - Confidence threshold: Store OCR confidence score, flag low-confidence results for manual review
  - Error handling: If OCR fails or confidence is low, provide manual input mode

### Asynchronous Processing: Pub/Sub vs Cloud Tasks
- **Context**: OCR processing should not block upload API response; need async worker pattern
- **Sources Consulted**:
  - [Choosing Pub/Sub or Cloud Tasks](https://cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks)
  - [Cloud Tasks vs Pub/Sub Comparison](https://medium.com/google-cloud/cloud-tasks-or-pub-sub-8dcca67e2f7a)
  - [Migrating From Cloud Tasks to Pub/Sub](https://www.fullstory.com/blog/migrating-cloud-tasks-to-cloud-pub-sub/)
- **Findings**:
  - **Pub/Sub (implicit invocation)**: Event-driven, 1-to-many, decoupled publishers/subscribers, ~100ms latency
  - **Cloud Tasks (explicit invocation)**: Point-to-point, rate control, retry precision, task scheduling
  - Use cases:
    - Pub/Sub: Event broadcasting (one upload → multiple subscribers: OCR, thumbnail generation, analytics)
    - Cloud Tasks: Controlled execution (rate limiting to avoid overwhelming OCR API quotas)
  - Retry strategies: Cloud Tasks offers fine-grained retry configs; Pub/Sub has simpler exponential backoff
  - Dead letter queues: Both support DLQ for failed messages
- **Implications**:
  - **Chosen pattern**: Pub/Sub for event publishing (image uploaded) → Cloud Tasks for controlled OCR worker execution
  - Flow: Upload API → publish to Pub/Sub topic → Pub/Sub subscription triggers Cloud Tasks → worker calls Cloud Vision API
  - Benefits: Event-driven decoupling + rate control for external API calls
  - Monitoring: Track message age, DLQ depth, worker latency

### Architecture Pattern Selection
- **Context**: Define overall system architecture for maintainability, testability, and future scalability
- **Sources Consulted**:
  - [Clean Architecture in Go](https://threedots.tech/post/introducing-clean-architecture/)
  - [Hexagonal Architecture Guide](https://www.happycoders.eu/software-craftsmanship/hexagonal-architecture/)
  - [DDD, Hexagonal, Clean Architecture Integration](https://herbertograca.com/2017/11/16/explicit-architecture-01-ddd-hexagonal-onion-clean-cqrs-how-i-put-it-all-together/)
  - [Hexagonal Architecture for Microservices](https://dev.to/jsalio/hexagonal-architecture-enabling-horizontal-scalability-and-seamless-microservices-transition-52hg)
- **Findings**:
  - Hexagonal Architecture: Ports & Adapters pattern, isolates domain logic from infrastructure
  - Clean Architecture: Similar goals, adds explicit layers (entities, use cases, interface adapters, frameworks)
  - Go implementations: Idiomatic approach mixes Hexagonal + Clean concepts
  - TypeScript implementations: 330+ repos on GitHub using Hexagonal Architecture
  - Benefits: Testability (mock infrastructure), portability (swap adapters), domain focus
  - Scalability: Hexagonal enables easy extraction to microservices (core logic unchanged, swap adapters)
  - Best practice 2025: Start with modular monolith, extract services when boundaries stabilize
- **Implications**:
  - **Selected pattern**: Hexagonal Architecture with Clean Architecture layers
  - Domain boundaries: Transactions, Categories, Receipts, Knowledge (memos/search), Users
  - Ports: Repository interfaces (database), Storage interfaces (Cloud Storage), OCR interfaces (Vision API), Event interfaces (Pub/Sub)
  - Adapters: Firestore adapter, Cloud Storage adapter, Cloud Vision adapter, Pub/Sub adapter
  - Future migration: Swap Firestore adapter for PostgreSQL adapter without changing domain logic

### Multi-Environment Infrastructure with Terraform
- **Context**: Manage dev/staging/prod environments with infrastructure as code
- **Sources Consulted**:
  - [Terraform Best Practices on Google Cloud](https://medium.com/@truonghongcuong68/terraform-best-practices-on-google-cloud-a-practical-guide-057f96b19489)
  - [How to Manage Terraform Multiple Environments 2025](https://www.microtica.com/blog/terraform-multiple-environments)
  - [Guide to Terraform for Multi-Environment GCP Infrastructure](https://medium.com/@dviniukov/guide-to-terraform-for-multi-environment-gcp-infrastructure-401e9b3b2443)
  - [Build Production-Ready GCP Infrastructure with Terraform 2025](https://dev.to/livingdevops/build-production-ready-google-cloud-infrastructure-with-terraform-in-2025-1jj7)
- **Findings**:
  - **Recommended approach**: Separate directories with isolated state files (not workspaces)
  - Directory structure: `terraform/modules/`, `terraform/environments/{dev,staging,prod}/`
  - Modules: Reusable infrastructure components (VPC, GKE, Cloud Run, etc.)
  - State management: Remote state in Cloud Storage with locking
  - Security: Workload Identity Federation for keyless authentication (prod), principle of least privilege
  - CI/CD integration: Automated `terraform plan` on PR, `terraform apply` on merge
  - Environment variables: Use `.tfvars` files per environment for configuration
- **Implications**:
  - Structure: `terraform/modules/{network,compute,storage,iam}`, `terraform/environments/{dev,staging,prod}/main.tf`
  - State backend: GCS bucket with versioning enabled, separate bucket or prefix per environment
  - Deployment: CI/CD pipeline validates and applies changes environment by environment
  - Cost control: Dev environment uses smaller instance sizes, reduced redundancy

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Layered Architecture | Traditional N-tier (presentation, business, data) | Simple, widely understood | Tight coupling between layers, difficult to test in isolation | Not recommended for this feature set |
| Hexagonal (Ports & Adapters) | Domain core with infrastructure adapters | Clear boundaries, testable, infrastructure-agnostic | Requires discipline to maintain boundaries, initial setup overhead | **Selected** - Aligns with future scalability goals |
| Clean Architecture | Concentric layers with dependency inversion | Explicit separation of concerns, framework independence | Can be over-engineered for simple apps | Use concepts but avoid strict layer enforcement |
| Event-Driven | Async message passing between services | Decoupled, scalable, resilient | Complexity in debugging, eventual consistency | Use for OCR processing only, not entire system |
| Microservices | Distributed services per domain | Independent scaling, technology diversity | Operational overhead, network latency, data consistency | Defer until scale requires it; start with modular monolith |

**Selected Approach**: Hexagonal Architecture with Clean Architecture principles, implemented as modular monolith initially.

## Design Decisions

### Decision: Hexagonal Architecture for Backend
- **Context**: Need architecture that supports learning goals (clean design) and future scalability (potential microservices)
- **Alternatives Considered**:
  1. Layered Architecture — simpler but tightly coupled
  2. Pure Clean Architecture — over-engineered for initial scope
  3. Hexagonal Architecture — balance of structure and pragmatism
- **Selected Approach**: Hexagonal Architecture
  - **Core domain**: Transaction, Category, Receipt, Knowledge, User entities and use cases
  - **Ports**: Repository, Storage, OCR, EventPublisher interfaces
  - **Adapters**: Firestore, Cloud Storage, Cloud Vision, Pub/Sub implementations
- **Rationale**:
  - Learning objective: Practice separating domain logic from infrastructure
  - Future-proof: Easy to swap Firestore for PostgreSQL by replacing adapter
  - Testability: Mock ports for unit testing domain logic
  - Scalability: Extract domains to microservices without changing core logic
- **Trade-offs**:
  - **Benefits**: Clear boundaries, testable, maintainable
  - **Compromises**: Initial setup cost, requires architectural discipline
- **Follow-up**: Validate port/adapter boundaries during implementation; adjust if over-abstracted

### Decision: Pub/Sub + Cloud Tasks for OCR Processing
- **Context**: OCR processing takes seconds; cannot block upload API response
- **Alternatives Considered**:
  1. Synchronous processing — blocks user, poor UX
  2. Cloud Tasks only — less decoupled, harder to add future subscribers
  3. Pub/Sub only — harder to control rate limiting for Vision API
  4. Pub/Sub + Cloud Tasks — event-driven + rate control
- **Selected Approach**: Pub/Sub + Cloud Tasks hybrid
  - Upload API publishes "receipt.uploaded" event to Pub/Sub topic
  - Pub/Sub push subscription triggers Cloud Tasks queue
  - Cloud Tasks worker calls Cloud Vision API with rate limiting
- **Rationale**:
  - Event-driven: Easy to add future subscribers (thumbnail generation, analytics)
  - Rate control: Cloud Tasks manages quota to avoid Vision API throttling
  - Resilience: Retry logic and DLQ for failed OCR processing
- **Trade-offs**:
  - **Benefits**: Decoupled, scalable, resilient
  - **Compromises**: Two-component pattern adds complexity vs. single queue
- **Follow-up**: Monitor message latency; if Pub/Sub→Tasks adds significant delay, consider direct Cloud Tasks

### Decision: Firestore First, PostgreSQL Migration Later
- **Context**: Learning project with low initial cost; need relational features eventually
- **Alternatives Considered**:
  1. PostgreSQL from start — higher cost, overkill for learning phase
  2. Firestore only — insufficient for future analytics and complex queries
  3. Firestore → PostgreSQL migration path — balance cost and scalability
- **Selected Approach**: Start with Firestore, design for PostgreSQL migration
  - Initial: Firestore with normalized-style references (document IDs, not nested objects)
  - Data model: Define entities/relationships now, implement in Firestore with clear structure
  - Migration: Phase 1 JSONB storage, Phase 2 extract critical fields, Phase 3 full relational schema
- **Rationale**:
  - Cost: Firestore free tier covers learning phase usage
  - Learning: Practice NoSQL first, then relational migration
  - Future-proof: PostgreSQL supports advanced analytics, complex joins
- **Trade-offs**:
  - **Benefits**: Low initial cost, gradual learning curve
  - **Compromises**: Migration work required later, dual data model maintenance during transition
- **Follow-up**: Document entity relationships in design; validate migration compatibility

### Decision: NextAuth.js for Frontend Authentication
- **Context**: Integrate Google Cloud Identity Platform with Next.js frontend
- **Alternatives Considered**:
  1. Custom JWT implementation — reinventing the wheel, security risk
  2. Firebase SDK directly — tightly couples frontend to Firebase
  3. NextAuth.js (Auth.js) — standard library for Next.js auth
- **Selected Approach**: NextAuth.js with Google Provider
  - Configure Google OAuth credentials in GCP Console
  - NextAuth.js handles token exchange and session management
  - Custom backend validation using Firebase Admin SDK
- **Rationale**:
  - Industry standard: NextAuth.js is the de facto auth library for Next.js in 2025
  - TypeScript support: Built-in type definitions
  - Security: Handles CSRF protection, session cookies, token rotation
  - Flexibility: Easy to add additional providers (email/password, GitHub, etc.)
- **Trade-offs**:
  - **Benefits**: Secure, well-tested, feature-rich
  - **Compromises**: Adds dependency, requires understanding NextAuth.js concepts
- **Follow-up**: Test session persistence across page refreshes; validate token expiration handling

### Decision: Echo Framework for Backend API
- **Context**: Need Go web framework for REST API on Cloud Run
- **Alternatives Considered**:
  1. Gin — more popular, lighter weight
  2. Fiber — fastest, Express.js-like API
  3. Echo — balanced structure and performance
- **Selected Approach**: Echo framework
  - Middleware chain: Logger → CORS → JWT → Recovery → Routes
  - RESTful routing with parameter binding and validation
  - Built-in support for HTTP/2, WebSocket (future use)
- **Rationale**:
  - Structure: Echo provides more built-in structure than Gin, suitable for medium-sized API
  - Middleware: Robust middleware ecosystem (JWT, CORS, rate limiting)
  - Learning: Good documentation and examples for Cloud Run deployment
  - Community: Active maintenance, 16% adoption among Go developers (2025)
- **Trade-offs**:
  - **Benefits**: Structured, performant, well-documented
  - **Compromises**: Slightly less popular than Gin, smaller ecosystem
- **Follow-up**: Benchmark API performance on Cloud Run; ensure latency targets met

### Decision: Terraform with Separate Environments
- **Context**: Manage GCP infrastructure as code for dev/staging/prod
- **Alternatives Considered**:
  1. Terraform workspaces — shared code, state isolation
  2. Separate directories — full environment isolation
  3. Manual GCP console — no reproducibility, error-prone
- **Selected Approach**: Terraform with separate environment directories
  - Structure: `terraform/modules/`, `terraform/environments/{dev,staging,prod}/`
  - Shared modules for reusable components (network, compute, storage)
  - Environment-specific `.tfvars` for configuration (instance sizes, budgets)
  - Remote state in GCS with locking
- **Rationale**:
  - Isolation: Separate state files prevent cross-environment changes
  - CI/CD: Easier to implement environment-specific pipelines
  - Best practice: Recommended approach for production environments (2025 consensus)
  - Learning: Practice real-world IaC patterns
- **Trade-offs**:
  - **Benefits**: Full isolation, CI/CD-friendly, production-ready
  - **Compromises**: More directories to maintain, potential code duplication (mitigated by modules)
- **Follow-up**: Set up remote state backend early; implement CI/CD validation

## Risks & Mitigations

- **Risk: Firestore → PostgreSQL migration complexity**
  - Mitigation: Design normalized data model from start; use document references (IDs) instead of nesting; test migration with sample data in dev environment

- **Risk: Cloud Vision API costs escalate with high usage**
  - Mitigation: Implement rate limiting on upload endpoint (e.g., 10 receipts/hour per user in free tier); monitor API usage with Cloud Monitoring alerts

- **Risk: OCR extraction accuracy insufficient for Japanese receipts**
  - Mitigation: Use DOCUMENT_TEXT_DETECTION mode; implement confidence score threshold; provide manual correction UI; consider GPT-4 post-processing if budget allows

- **Risk: Hexagonal Architecture over-abstraction slows development**
  - Mitigation: Start with clear port definitions (Repository, Storage, OCR); add adapters only when needed; avoid premature optimization

- **Risk: Multi-environment Terraform state drift**
  - Mitigation: Remote state in GCS with locking; CI/CD enforces `terraform plan` before apply; regular drift detection with `terraform plan -refresh-only`

- **Risk: NextAuth.js session handling issues (token expiration, refresh)**
  - Mitigation: Configure appropriate session expiration (default 30 days); implement token refresh logic; test logout/re-auth flows

- **Risk: Cloud Run cold start latency impacts user experience**
  - Mitigation: Set min instances to 1 for critical services (API gateway); use Cloud Trace to identify bottlenecks; optimize container image size

## References

### Authentication & Identity
- [Firebase Authentication: Verify ID Tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens) — Official Firebase Admin SDK token verification guide
- [NextAuth.js Documentation](https://next-auth.js.org/) — Official NextAuth.js documentation
- [Echo JWT Middleware](https://echo.labstack.com/docs/middleware/jwt) — Echo framework JWT middleware guide
- [Firebase JWT Echo Middleware](https://pkg.go.dev/github.com/reedom/echo-middleware-firebasejwt) — Go package for Firebase JWT validation

### Cloud Services
- [Google Cloud Vision API OCR](https://cloud.google.com/vision/docs/ocr) — Official Cloud Vision OCR documentation
- [Choosing Pub/Sub or Cloud Tasks](https://cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks) — Official Google Cloud comparison
- [Cloud Run Documentation](https://cloud.google.com/run/docs) — Official Cloud Run deployment guides

### Architecture & Patterns
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) — Original Clean Architecture article
- [Hexagonal Architecture Guide](https://www.happycoders.eu/software-craftsmanship/hexagonal-architecture/) — Comprehensive hexagonal architecture tutorial
- [Explicit Architecture (DDD, Hexagonal, Clean)](https://herbertograca.com/2017/11/16/explicit-architecture-01-ddd-hexagonal-onion-clean-cqrs-how-i-put-it-all-together/) — Integration of multiple architectural patterns

### Infrastructure & DevOps
- [Terraform Best Practices on Google Cloud 2025](https://medium.com/@truonghongcuong68/terraform-best-practices-on-google-cloud-a-practical-guide-057f96b19489) — Comprehensive Terraform guide for GCP
- [Google Cloud Database Migration Service](https://cloud.google.com/database-migration) — Official migration service documentation
- [Firestore to PostgreSQL Migration](https://ice-panda.medium.com/migrate-data-from-firestore-to-cloud-sql-on-google-cloud-c89b8feb1d70) — Practical migration guide
