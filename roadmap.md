# Roadmap: distributed-wagering-processor

11 stages · 49 cards. Suggested order: top to bottom.

## Table of Contents

- **0 · Setup and Fundamentals**: Environment setup from scratch, TypeScript review, and DDD and financial-system concepts.
  - 0.1 Prepare the Development Environment
  - 0.2 Study: TypeScript Review (What the Project Requires)
  - 0.3 Study: Tactical DDD and Hexagonal Architecture
  - 0.4 Study: Money, Ledgers, Idempotency, and At-Least-Once Delivery
  - 0.5 Create the NestJS Project with Bun
  - 0.6 Define Folder Structure and Conventions
  - 0.7 Docker Compose: PostgreSQL + LocalStack (SQS)
- **1 · Pure Domain**: Domain model in pure TypeScript, without NestJS or a database. Everything covered by unit tests (`bun test`).
  - 1.1 Money (value object) + tests
  - 1.2 Domain Errors and FailureCode Taxonomy
  - 1.3 WalletLedgerEntry (immutable) + tests
  - 1.4 Wallet (aggregate root) + tests
  - 1.5 WagerTransaction (state machine) + tests
  - 1.6 Reference and Reversal Rules (domain service) + tests
  - 1.7 Canonical Payload Hash (idempotency) + tests
  - 1.8 IntegrationEvent + concrete events
  - 1.9 InboxMessage and OutboxMessage + tests
- **2 · Persistence**: PostgreSQL + MikroORM. The schema (constraints and indexes) is evaluated directly.
  - 2.1 Study: MikroORM and PostgreSQL Transactions
  - 2.2 Configure MikroORM in Nest and the CLI
  - 2.3 Initial Migration with All Constraints
  - 2.4 Records, Mappers, and Repositories (ports + adapters)
  - 2.5 Integration Tests: Migrations and Constraints
- **3 · Use Cases and Concurrency**: The core challenge—processing transactions correctly under concurrency with persistent idempotency.
  - 3.1 Study: Concurrency Strategies and the Documented Decision
  - 3.2 Use Case: OpenWallet
  - 3.3 Use Case: ProcessWagerTransaction (the main flow)
  - 3.4 Idempotency Under Race Conditions: Replay and Conflict
  - 3.5 Required Scenario: 100.00 with two concurrent 80.00 bets
- **4 · HTTP API**: Section 9 endpoints with consistent status mapping.
  - 4.1 Input Validation and HTTP Status Mapping
  - 4.2 Wallet Endpoints: create, retrieve, and paginated ledger
  - 4.3 Wagering Endpoints: submit and retrieve transactions
  - 4.4 Authentication: Documented Extension Point
- **5 · SQS Messaging**: FIFO queue consumer with inbox, post-commit acknowledgments, retries, and DLQ.
  - 5.1 Study: SQS (FIFO, visibility timeout, DLQ)
  - 5.2 SQS Consumer Reusing the Use Case
  - 5.3 Graceful shutdown (SIGTERM)
- **6 · Outbox and Workers**: Reliable event publishing and out-of-order reference reprocessing.
  - 6.1 Outbox Publisher Worker (multi-instance)
  - 6.2 PENDING_REFERENCE Worker (out-of-order references)
- **7 · Operations and Observability**: Reconciliation, health checks, structured logging, and metrics.
  - 7.1 Wallet Reconciliation
  - 7.2 Health Checks: Liveness and Readiness
  - 7.3 Structured Logs with correlationId
  - 7.4 Metrics (Prometheus)
- **8 · Integration and Chaos Testing**: Real PostgreSQL and SQS, multiple instances, and injected failures. Final invariant: balance == ledger.
  - 8.1 Test Infrastructure: Real Database, LocalStack, and Helpers
  - 8.2 Integration Tests: Atomicity, Inbox, Retry, DLQ, and Restart
  - 8.3 Tests with ≥ 3 Instances and Real Failures
- **9 · Documentation and Portfolio**: README, ARCHITECTURE.md, and portfolio polish.
  - 9.1 README.md
  - 9.2 ARCHITECTURE.md: Decisions, Trade-offs, and Limitations
  - 9.3 CI with GitHub Actions and Final Polish
- **10 · Optional Items**: Enhancements. Only after everything above is green.
  - 10.1 Load Test (bun run test:load)
  - 10.2 Authentication with Keycloak or Zitadel
  - 10.3 OpenTelemetry and Dashboard
  - 10.4 Double-Entry Ledger

---

# 0 · Setup and Fundamentals

_Environment setup from scratch, TypeScript review, and DDD and financial-system concepts._

## 0.1 Prepare the Development Environment

Labels: `setup`

**Objective:** Have everything installed and working before writing code.

#### Tasks
- [ ] Decide where to run it: native Windows or **WSL2** (WSL2 is recommended because Docker, Bun, and shell scripts behave like they do on Linux CI)
- [ ] Install **Bun 1.x**
  - Linux/WSL/macOS: `curl -fsSL https://bun.sh/install | bash`
  - Windows native: `powershell -c "irm bun.sh/install.ps1 | iex"`
- [ ] Install **Docker** (Docker Desktop with the WSL2 backend, or Docker Engine on Linux) and verify `docker compose version`
- [ ] Install or update **git** and the **GitHub CLI** (`gh auth login`)
- [ ] VS Code plus extensions: ESLint or oxc, Prettier, Docker, PostgreSQL (or DBeaver), "Pretty TypeScript Errors"
- [ ] Verify versions: `bun --version`, `docker --version`, `git --version`
- [ ] Clean the repository: remove everything except README and create the commit `chore: reset project`

#### Done When
- `bun --version` shows 1.x and `docker run hello-world` works

## 0.2 Study: TypeScript Review (What the Project Requires)

Labels: `study`

**Objective:** Review only the TypeScript concepts used in the project. Complete the exercises in a standalone file (`scratch/ts.ts`) and run them with `bun run scratch/ts.ts`.

#### Topics
- [ ] `type` vs. `interface`: when to use each one (interface for DTOs/props, type for unions)
- [ ] Union types and literal types (`'BET' | 'WIN'`) vs. `enum`: pros and cons
- [ ] Classes: `private`, `protected`, `readonly`, `public`, and constructor parameter properties
- [ ] **Private constructor + static factories** (`static create()`, `static rehydrate()`), a central pattern of the challenge
- [ ] Getters (`get balance()`) and why state should be exposed only through them
- [ ] Custom errors: `class InsufficientFundsError extends Error`, with the `code` property
- [ ] `unknown` vs. `any`, narrowing (`typeof`, `instanceof`, discriminated unions)
- [ ] Basic generics (`IntegrationEvent<T>`, `Readonly<T>`, `Record<K, V>`)
- [ ] `import`/`export`, `import type`
- [ ] `async`/`await` and `Promise<T>`
- [ ] `tsconfig` options we will use: `strict`, `noUncheckedIndexedAccess`, `experimentalDecorators`, and `emitDecoratorMetadata`
- [ ] Decorators: what they are and how NestJS uses them (concept only)

#### Exercise
- [ ] Write an immutable `Temperature` class with a private constructor, `static fromCelsius()`, and an `add()` method that returns a new instance; include a custom error for invalid values and 3 tests with `bun test`

#### Done When
- You should be able to explain why `private constructor` + `static create()` protects invariants

## 0.3 Study: Tactical DDD and Hexagonal Architecture

Labels: `study`

**Objective:** Understand the terminology before modeling. Write it in your own words because it will form the basis of ARCHITECTURE.md.

#### Topics
- [ ] **Value Object**: immutable, equality based on value (e.g. `Money`)
- [ ] **Entity**: distinct identity whose state changes over time (e.g. `WagerTransaction`)
- [ ] **Aggregate / Aggregate Root**: consistency boundary; modified only through the root (e.g. `Wallet`)
- [ ] **Invariants** and where they live (in the **domain** and the database schema)
- [ ] **Domain Events** x **Integration Events**
- [ ] **Repository** as a port (interface in `application`, implementation in `infrastructure`)
- [ ] Layers: `domain` → `application` (use cases + ports) → `infrastructure` (adapters) → `presentation` (HTTP/SQS)
- [ ] Dependency rule: the domain does not import NestJS, MikroORM, or any infrastructure code
- [ ] `create` vs. `rehydrate`: `create` validates rules; `rehydrate` only reconstructs what has already been persisted

#### Suggested Resources
- "Domain-Driven Design Distilled" (Vaughn Vernon), chapters on Aggregates and Value Objects
- Artigo "Hexagonal Architecture" (Alistair Cockburn)

#### Done When
- You should be able to draw on paper who calls whom: Controller → UseCase → Port ← Adapter

## 0.4 Study: Money, Ledger, Idempotency, and At-Least-Once Delivery

Labels: `study`

**Objective:** Understand the problems evaluated by the challenge before looking at code.

#### Topics
- [ ] Why `0.1 + 0.2 !== 0.3`: floating-point arithmetic and why money must never be a `number`
- [ ] Decimal values with arbitrary precision (`decimal.js`) and `NUMERIC(p,s)` in PostgreSQL
- [ ] Banker’s rounding (`ROUND_HALF_EVEN`) with a fixed scale of 2 decimal places
- [ ] **Ledger**: immutable append-only record; the balance is a *materialization* of the ledger
- [ ] Reconciliation: ledger sum == stored balance
- [ ] (Optional) double-entry bookkeeping
- [ ] **At-least-once delivery**: the same message may arrive 2+ times and out of order
- [ ] **Idempotency**: idempotency key + payload hash; “replay” vs. “conflict”
- [ ] **Lost update** and race condition: the read → calculate → update problem
- [ ] **Transactional Outbox** and **Inbox**: why they exist and which problem they solve (dual-write)

#### Suggested Resources
- "Designing Data-Intensive Applications", chap. 7 (Transactions)
- microservices.io → Transactional Outbox, Idempotent Consumer
- Stripe Engineering → "Designing robust and predictable APIs with idempotency"

#### Done When
- You should be able to explain the “two 80 bets with a balance of 100” scenario and why it fails without a lock

## 0.5 Create the NestJS Project with Bun

Labels: `setup`

**Objective:** A running skeleton with Bun, strict TypeScript, and `bun test`.

#### Tasks
- [ ] Generate the project without installing dependencies:
  `bunx @nestjs/cli new . --skip-git --skip-install --package-manager npm`
- [ ] `bun install` (generates `bun.lock`)
- [ ] Remove Jest: `@types/jest`, `jest`, `ts-jest`, the `jest` section from package.json and the Jest `test:*` scripts
- [ ] `bun add -d @types/bun` and adjust `types` in tsconfig
- [ ] Convert the example test to `import { describe, it, expect } from 'bun:test'`
- [ ] tsconfig: `strict: true`, `noUncheckedIndexedAccess: true`, `noImplicitOverride: true`, `experimentalDecorators` and `emitDecoratorMetadata` enabled
- [ ] Scripts in package.json: `dev` (`bun --watch src/main.ts`), `start`, `test`, `typecheck` (`tsc --noEmit`), `lint`, `format`
- [ ] Prettier + lint (oxlint or ESLint); choose one
- [ ] Update `.gitignore` (node_modules, dist, .env, coverage)
- [ ] Create `.env.example`
- [ ] Set `name` in package.json to `distributed-wagering-processor`

#### Done When
- `bun run dev` starts Nest, and `curl localhost:3000` responds
- `bun test` and `bun run typecheck` pass

## 0.6 Define Folder Structure and Conventions

Labels: `setup` `docs`

**Objective:** Decide now so you do not keep changing course later.

#### Suggested Structure
```
src/
  shared/          # Money, IntegrationEvent, OutboxMessage, generic ports (Clock, IdGenerator)
    domain/ application/ infrastructure/ presentation/
  modules/
    wallet/        # Wallet, WalletLedgerEntry, OpenWallet, Reconcile
    wager/         # WagerTransaction, ProcessWagerTransaction, consumer SQS
    outbox/        # publisher worker
    health/
      domain/ application/ infrastructure/ presentation/
test/
  integration/ concurrency/ helpers/
```

#### Tasks
- [ ] Create the folders (empty, with `.gitkeep`)
- [ ] File naming convention: `kebab-case` plus a role suffix (`wallet.ts`, `open-wallet.use-case.ts`, `wallet.repository.ts`, `wallet.record.ts`, `wallet.controller.ts`)
- [ ] Place unit tests beside their source files (`money.spec.ts`); integration tests in `test/`
- [ ] Write code comments in English
- [ ] Commit convention (Conventional Commits: `feat:`, `fix:`, `test:`, `chore:`, `docs:`)
- [ ] Document these decisions in a short README section

#### Done When
- Folder structure committed and conventions documented

## 0.7 Docker Compose: PostgreSQL + LocalStack (SQS)

Labels: `setup` `messaging`

**Objective:** Start the local infrastructure with a single command.

#### Tasks
- [ ] `docker-compose.yml` with:
  - `postgres:16-alpine`, volume, healthcheck (`pg_isready -U $DB_USER -d $DB_NAME`)
  - `localstack/localstack` with `SERVICES=sqs`, a healthcheck, and the init script mounted at `/etc/localstack/init/ready.d/`
  - If the current LocalStack version requires a token/account, use **MiniStack**, which is also accepted by the specification
- [ ] Script `docker/localstack/init-queues.sh` (use `awslocal`):
  - create `wager-transactions-dlq.fifo` (`FifoQueue=true`)
  - create `wager-transactions.fifo` with `FifoQueue=true`, `VisibilityTimeout`, and `RedrivePolicy` pointing to the DLQ with `maxReceiveCount` (e.g. 5)
  - create a queue/topic for events published by the outbox (ex.: `wager-events.fifo`)
- [ ] Do not use a fixed `container_name` (it prevents cleanly scaling to multiple instances)
- [ ] Remove `version:` (obsolete)
- [ ] `.env.example` with `DB_*`, `AWS_ENDPOINT_URL`, `AWS_REGION`, `AWS_ACCESS_KEY_ID=test`, `AWS_SECRET_ACCESS_KEY=test`, queue URLs
- [ ] Separate database for tests (ex.: `wager_test`), created by a Postgres init SQL script

#### Done When
- `docker compose up -d` leaves both services *healthy*
- `awslocal sqs list-queues` (or `aws --endpoint-url ...`) shows the 3 queues

---

# 1 · Pure Domain

_Domain model in pure TypeScript, without NestJS or a database. Everything covered by unit tests (`bun test`)._

## 1.1 Money (Value Object) + Tests

Labels: `domain`

**Objective:** The most important building block. There should be no `number` anywhere.

#### Tasks
- [ ] `bun add decimal.js`
- [ ] Use a dedicated `Decimal.clone({ rounding: ROUND_HALF_EVEN, ... })` configuration to avoid changing the global configuration
- [ ] Interface `MoneyProps { amount: string; currency: string }`
- [ ] `private constructor`, `static from(props)`, `static zero(currency)`
- [ ] Validate with a regular expression: only `^\d+\.\d{2}$` (no negatives, scientific notation, or spaces; exactly 2 decimal places)
- [ ] `add`, `subtract`, `negate` (return a new instance)
- [ ] `isZero`, `isPositive`, `isNegative`, `isLessThan`, `equals`
- [ ] `toString()` always uses 2 decimal places; `toJSON()` returns `MoneyProps`
- [ ] `assertSameCurrency` throws `CurrencyMismatchError`
- [ ] Supported ISO-4217 currencies (BRL required; keep the model multi-currency)
- [ ] Maximum limit compatible with the `NUMERIC` column you will use
- [ ] Normalize `-0.00` to `0.00`
- [ ] Domain errors with a stable `code`

#### Tests
- [ ] accepts `"25.00"`, `"0.00"`
- [ ] rejects `""`, `"25"`, `"25.5"`, `"25.001"`, `"-1.00"`, `"1e3"`, `"NaN"`, `"Infinity"`, `" 25.00"`, `"01.00"`
- [ ] `0.10 + 0.20 == 0.30`
- [ ] subtract, negate, comparisons
- [ ] **currency conflict** in add/subtract/isLessThan/equals
- [ ] invalid currency
- [ ] limit overflow
- [ ] immutability (the operation does not alter the original instance)
- [ ] `toJSON()` produces the contract format

#### Done When
- All tests pass and no monetary value is represented as a `number`

## 1.2 Domain Errors and FailureCode Taxonomy

Labels: `domain` `docs`

**Objective:** Every rejection reason has a stable, machine-readable code, so the provider knows whether to retry, correct the payload, or stop.

#### Tasks
- [ ] `FailureCode` (union of string literals or enum). Suggested initial set:
  - `INSUFFICIENT_FUNDS`: BET without sufficient balance
  - `REVERSAL_INSUFFICIENT_FUNDS`: ROLLBACK of WIN would leave a negative balance (**different from the previous case, as required by the specification)
  - `WALLET_NOT_FOUND`, `WALLET_PLAYER_MISMATCH`, `CURRENCY_MISMATCH`
  - `REFERENCE_NOT_FOUND`: PENDING_REFERENCE retries exhausted
  - `REFERENCE_MISMATCH`: provider/player/wallet/currency/round mismatch
  - `REFERENCE_INVALID_KIND`: REFUND of something other than BET, etc.
  - `REFERENCE_NOT_PROCESSED`
  - `REFERENCE_ALREADY_REVERSED`
  - `AMOUNT_MISMATCH`: value differs from the reference
- [ ] For every code: category (`business` / `permanent` / `transient`) and provider action (`do_not_retry`, `fix_payload`, `retry`)
- [ ] Base class `DomainError` with `code`, plus subclasses
- [ ] Separate programming error: `InvalidTransactionStateError` (transition from a terminal state)
- [ ] Table in ARCHITECTURE.md

#### Done When
- Failure-code table documented and errors used in the next cards

## 1.3 WalletLedgerEntry (Immutable) + Tests

Labels: `domain`

**Objective:** A structurally immutable ledger entry (no setters, no transition methods).

#### Tasks
- [ ] `enum LedgerDirection { Debit = 'DEBIT', Credit = 'CREDIT' }`
- [ ] Fields marked `readonly`: `id`, `walletId`, `transactionId`, `direction`, `money`, `balanceBefore`, `balanceAfter`, `createdAt`
- [ ] `static create(props)` validates:
  - positive `money`
  - the same currency throughout
  - `balanceBefore ± money === balanceAfter`
  - `balanceAfter` is not negative
- [ ] `static rehydrate(state)` without revalidation
- [ ] `isBalanced()`

#### Tests
- [ ] valid credits and debits
- [ ] Incorrect arithmetic throws an error
- [ ] Different currencies throw an error
- [ ] Zero or negative values throw an error

#### Done When
- Without a cast, there is no way to alter a ledger entry after it is created

## 1.4 Wallet (Aggregate Root) + Tests

Labels: `domain`

**Objective:** Balance and ledger entries are created together, making it impossible to change the balance without a ledger entry.

#### Tasks
- [ ] `private constructor` with `id`, `playerId`, `currency`, `_balance`, `_version`, `createdAt`, `_updatedAt`
- [ ] `static open({ id, playerId, initialBalance })`: `version = 1`
- [ ] `static rehydrate(state)`
- [ ] Getters: `balance`, `version`, `updatedAt`
- [ ] `debit(money, transactionId, at)` → returns `WalletLedgerEntry`; throws `InsufficientFundsError` if the balance would become negative
- [ ] `credit(money, transactionId, at)` → returns `WalletLedgerEntry`
- [ ] Every movement increments `version` **only when the balance changes**
- [ ] `assertSameCurrency`
- [ ] Decide whether opening with a balance > 0 creates the OPENING ledger entry here or in the use case. Document the choice

#### Tests
- [ ] open with zero and positive balances
- [ ] debit with sufficient, exact, and insufficient balances
- [ ] credit
- [ ] version starts at 1 and increments
- [ ] different currency
- [ ] `balanceBefore`/`balanceAfter` of the returned ledger entry match the wallet balance

#### Done When
- The balance invariants from section 6.2 are covered by tests

## 1.5 WagerTransaction (State Machine) + Tests

Labels: `domain`

**Objective:** Explicit states and transitions; terminal states never change.

#### Tasks
- [ ] Enums `WagerTransactionKind` (OPENING, BET, WIN, LOSS, REFUND, ROLLBACK) and `WagerTransactionStatus` (PENDING, PENDING_REFERENCE, PROCESSED, REJECTED, FAILED)
- [ ] `static create(props)`: starts in `PENDING`; validates that REFUND/ROLLBACK have `referenceExternalTransactionId`
- [ ] `static createOpening(...)` internal, so OPENING does not pass through the public creation path
- [ ] `static rehydrate(state)`
- [ ] Transitions: `markProcessed(refId, at)`, `markPendingReference()`, `reject(code)`, `fail(code)`
- [ ] Any transition from a terminal state → `InvalidTransactionStateError`
- [ ] Queries: `isTerminal()`, `affectsBalance()` (false for LOSS), `requiresReference()`, `matchesPayload(hash)`, `ledgerDirectionFor(reference?)`
- [ ] Field for the **observed result** (ex.: `balanceAfter` at the time of processing), required so replay can return the original balance
- [ ] Draw the state diagram in Mermaid for ARCHITECTURE.md

#### Tests
- [ ] everything valid transitions
- [ ] everything transitions from terminal states throw an error
- [ ] REFUND/ROLLBACK without a reference are rejected by `create`
- [ ] `ledgerDirectionFor`: BET→DEBIT, WIN/REFUND→CREDIT, ROLLBACK→inverse of the reference
- [ ] `matchesPayload` with matching/different hash

#### Done When
- State diagram documented and 100% of transitions tested

## 1.6 Reference and Reversal Rules (Domain Service) + Tests

Labels: `domain`

**Objective:** Centralize the section 7 rules in one place that can be tested without a database.

#### Tasks
- [ ] Create a function or class (ex.: `ReferencePolicy`) that receives the new transaction and reference and returns either success or `FailureCode`
- [ ] The reference must have the same provider, player, wallet, currency, and **round**
- [ ] REFUND may reference only BET; ROLLBACK may reference BET, WIN, or REFUND
- [ ] The reference must be PROCESSED
- [ ] The amount must equal the reference amount (no partial reversals)
- [ ] Already reversed by the same type → `REFERENCE_ALREADY_REVERSED` (the real guarantee comes from the unique database index; this is only a domain-level check)
- [ ] WIN may reference a BET from the same round (optional; document your interpretation)
- [ ] When applying it, a reversal that would leave a negative balance → `REVERSAL_INSUFFICIENT_FUNDS`

#### Tests (one per rule)
- [ ] BET / WIN / LOSS / REFUND / ROLLBACK: happy path
- [ ] each violation returns the correct code
- [ ] ROLLBACK of WIN with insufficient funds

#### Done When
- Every row in the section 7 table has at least one test

## 1.7 Canonical Payload Hash (Idempotency) + Tests

Labels: `domain` `concurrency`

**Objective:** The same business content produces the same hash regardless of key order.

#### Tasks
- [ ] Define the **subset of business fields** included in the hash (providerId, externalTransactionId, playerId, walletId, roundId, gameId, kind, money, referenceExternalTransactionId)
- [ ] Excluded from the hash: header, messageId, occurredAt, and other transport metadata
- [ ] Canonical JSON: recursively sorted keys, no whitespace; omit `undefined`
- [ ] `sha256` as hex (`Bun.CryptoHasher` or `node:crypto`)
- [ ] `PayloadHasher` port in application, with the implementation in infrastructure
- [ ] Document the algorithm in ARCHITECTURE.md

#### Tests
- [ ] same information in a different order → same hash
- [ ] different value → different hash
- [ ] transport metadata does not change the hash

#### Done When
- Algorithm documented and tested

## 1.8 IntegrationEvent + Concrete Events

Labels: `domain` `messaging`

**Objective:** Typed events with fixed `eventType` and `version` values defined by the type.

#### Tasks
- [ ] `abstract class IntegrationEvent<T>` with `eventId`, `aggregateId`, `correlationId`, `causationId?`, `occurredAt`, `data`, `abstract eventType`, `abstract version`, `toJSON()`
- [ ] Subclasses with `static from(...)`:
  - `WagerTransactionProcessed` (including LOSS)
  - `WagerTransactionRejected`
  - `WalletBalanceChanged` (only when the balance changes)
  - `WagerTransactionPendingReference`
- [ ] `data` uses `MoneyProps` (string), never a `Money` instance
- [ ] `occurredAt` serialized in ISO-8601

#### Tests
- [ ] `toJSON()` for each event has the envelope format
- [ ] `JSON.parse(JSON.stringify(evt.toJSON()))` is stable

#### Done When
- All four events exist and serialize correctly

## 1.9 InboxMessage and OutboxMessage + Tests

Labels: `domain` `messaging`

**Objective:** Models for inbound deduplication and reliable outbound publishing.

#### Tasks
- [ ] `InboxMessage.receive({ messageId, consumerName, payloadHash, receivedAt })`, `rehydrate`, `isProcessed`, `markProcessed(at)`
- [ ] `OutboxMessage.enqueue(event)`, `rehydrate`, `isPending`, `isDue(now)`, `markPublished(at)`, `scheduleRetry(now)`
- [ ] Exponential backoff with a cap and jitter in `scheduleRetry` (ex.: `min(base * 2^attempts, max)`)
- [ ] `Clock` port so tests can control time

#### Tests
- [ ] `scheduleRetry` increments `attempts` and advances `nextAttemptAt`
- [ ] `isDue` before/after the scheduled time
- [ ] `markPublished` makes `isPending()` false

#### Done When
- Both models tested, with time controlled by `Clock`

---

# 2 · Persistence

_PostgreSQL + MikroORM. The schema (constraints and indexes) is evaluated directly._

## 2.1 Study: MikroORM and PostgreSQL Transactions

Labels: `study` `persistence`

**Objective:** Understand the tooling before mapping the persistence model.

#### Topics
- [ ] EntityManager, **Unit of Work**, **Identity Map**, `em.fork()` per request
- [ ] `em.transactional(async (em) => ...)`
- [ ] `LockMode.PESSIMISTIC_WRITE` (= `SELECT ... FOR UPDATE`) and `LockMode.OPTIMISTIC`
- [ ] `EntitySchema` / `defineEntity` x decorators. To keep the domain independent of the ORM, use **separate records + mappers**
- [ ] Migrations: `up`/`down`, hand-written SQL with `this.addSql()` (required for CHECK constraints, partial indexes, and triggers)
- [ ] PostgreSQL: `NUMERIC(20,2)`, `CHECK`, `UNIQUE`, partial index, `ON CONFLICT DO NOTHING`, triggers
- [ ] Isolation levels (READ COMMITTED x REPEATABLE READ x SERIALIZABLE)

#### Done When
- You should be able to explain why the domain does not use `@Entity()` directly

## 2.2 Configure MikroORM in Nest and the CLI

Labels: `persistence` `setup`

#### Tasks
- [ ] `bun add @mikro-orm/core @mikro-orm/postgresql @mikro-orm/nestjs @mikro-orm/migrations`
- [ ] `bun add -d @mikro-orm/cli`
- [ ] **A single** config (`mikro-orm.config.ts`) used by both Nest and the CLI, without duplication
- [ ] Read environment variables with validation (fail at startup if one is missing)
- [ ] Point `entities` to your records (`*.record.ts`)
- [ ] Configure the CLI to run TypeScript with Bun (see the documentation for the installed version and test with `bunx mikro-orm debug`)
- [ ] Connection pool sized and documented
- [ ] Scripts: `db:migrate`, `db:migrate:down`, `db:migration:create`

#### Done When
- `bunx mikro-orm debug` finds the database and entities

## 2.3 Initial Migration with All Constraints

Labels: `persistence` `concurrency`

**Objective:** Invariants live in the database, not only in application code.

#### `wallets`
- [ ] `amount NUMERIC(20,2)`, `currency CHAR(3)`
- [ ] `UNIQUE (player_id, currency)`
- [ ] `CHECK (balance_amount >= 0)`, `CHECK (version >= 1)`

#### `wager_transactions`
- [ ] `UNIQUE (idempotency_key)`
- [ ] `UNIQUE (provider_id, external_transaction_id)`
- [ ] `CHECK` that `kind` and `status` are valid
- [ ] `CHECK (amount > 0)`
- [ ] `CHECK (kind NOT IN ('REFUND','ROLLBACK') OR reference_external_transaction_id IS NOT NULL)`
- [ ] `CHECK (status NOT IN ('REJECTED','FAILED') OR failure_code IS NOT NULL)`
- [ ] **Unique partial index** that guarantees “reverse only once”: `(reference_transaction_id, kind) WHERE status = 'PROCESSED' AND kind IN ('REFUND','ROLLBACK')`
- [ ] Worker index: `(status, next_attempt_at) WHERE status = 'PENDING_REFERENCE'`
- [ ] Observed-result columns (balance after) for replay

#### `wallet_ledger_entries`
- [ ] Foreign keys for wallet and transaction
- [ ] `UNIQUE (transaction_id, wallet_id)`: at most one ledger entry per transaction per wallet
- [ ] `CHECK (amount > 0)`, `CHECK (balance_after >= 0)`
- [ ] Arithmetic `CHECK` (CREDIT: after = before + amount; DEBIT: after = before - amount)
- [ ] **Trigger** `BEFORE UPDATE OR DELETE` that throws an exception (append-only)
- [ ] Index `(wallet_id, created_at, id)` for cursor pagination

#### `inbox_messages`
- [ ] `PRIMARY KEY (consumer_name, message_id)`

#### `outbox_messages`
- [ ] `payload JSONB`, `attempts`, `next_attempt_at`, and `published_at`
- [ ] Partial index `(next_attempt_at) WHERE published_at IS NULL`

#### General
- [ ] Functional `down` migration (reversible)
- [ ] Test `up` → `down` → `up`

#### Done When
- The migration applies and rolls back cleanly, and every constraint has an annotated rationale

## 2.4 Records, Mappers, and Repositories (Ports + Adapters)

Labels: `persistence` `domain`

**Objective:** Keep the domain pure while infrastructure handles translation.

#### Tasks
- [ ] Separate ORM records (`wallet.record.ts`, etc.) from domain classes
- [ ] Mappers `toDomain()` (uses `rehydrate`) and `toRecord()`
- [ ] Always represent Money ↔ `NUMERIC` as a **string** (configure the `pg` driver not to convert numeric values to numbers)
- [ ] Ports in `application/ports`:
  - `WalletRepository`: `findById`, `findByIdForUpdate` (lock), `save`
  - `WagerTransactionRepository`: `insertIfAbsent`, `findByIdempotencyKey`, `findByExternalId`, `save`, `findDuePendingReferences`
  - `LedgerRepository`: `append`, `listByWallet(cursor, limit)`, `sumByWallet`
  - `OutboxRepository`: `add`, `claimDue(limit)` (SKIP LOCKED), `save`
  - `InboxRepository`: `insertIfAbsent`
- [ ] Adapters in `infrastructure/persistence`
- [ ] Dependency injection via Nest tokens (`provide: WALLET_REPOSITORY`)

#### Done When
- No file under `domain/` imports anything from MikroORM or Nest

## 2.5 Integration Tests: Migrations and Constraints

Labels: `tests` `persistence`

**Objective:** Prove that the database rejects invalid states even if application code fails.

#### Tasks
- [ ] Helper that applies migrations to the test database and clears tables between tests
- [ ] Test every constraint by issuing raw SQL and expecting an error:
  - duplicate wallet (player + currency)
  - negative balance
  - duplicate idempotency key
  - two PROCESSED ROLLBACKs for the same reference
  - `UPDATE`/`DELETE` on the ledger
  - ledger entry with incorrect arithmetic
  - duplicate inbox entry
- [ ] Test `up` → `down` → `up`

#### Done When
- Every constraint has a red-to-green test

---

# 3 · Use Cases and Concurrency

_The core challenge: process transactions correctly under concurrency with persistent idempotency._

## 3.1 Study: Concurrency Strategies and the Documented Decision

Labels: `study` `concurrency`

#### Topics
- [ ] Pessimistic lock (`SELECT ... FOR UPDATE`) per wallet
- [ ] Optimistic locking (`version`) with a limited retry count
- [ ] Atomic conditional update (`UPDATE ... SET balance = balance - $1 WHERE id = $2 AND balance >= $1`)
- [ ] Deadlocks: use a consistent lock order
- [ ] Hot wallet: what happens with each strategy when one wallet receives heavy traffic
- [ ] Why global and in-memory locks are prohibited (multiple instances)

#### Decide and Document
- [ ] Selected strategy (suggested: **pessimistic locking per wallet**, plus `version` as an extra safeguard), with justification and trade-offs in ARCHITECTURE.md
- [ ] Lock timeout (`lock_timeout`) and how to handle a timeout (transient error)

#### Done When
- The “Concurrency” section of ARCHITECTURE.md is written

## 3.2 Use Case: OpenWallet

Labels: `domain` `persistence`

#### Tasks
- [ ] Within a transaction: create the wallet; if the initial balance is > 0, create the internal `OPENING` transaction (PROCESSED), the CREDIT ledger entry, and the outbox events
- [ ] Duplicate wallet (violation of `UNIQUE(player_id, currency)`) → conflict error
- [ ] IDs supplied by the `IdGenerator` (UUID v7 is a good choice because it is sortable)

#### Integration Tests
- [ ] opens with a zero balance → no ledger entry
- [ ] opens with 1000.00 → 1 OPENING + 1 CREDIT, balance == ledger
- [ ] duplicate → conflict

#### Done When
- The balance == ledger invariant holds immediately after opening

## 3.3 Use Case: ProcessWagerTransaction (Main Flow)

Labels: `concurrency` `persistence` `domain`

**Objective:** A use case reused by both the HTTP and SQS entry points.

#### Suggested Flow (all inside **one** SQL transaction)
1. [ ] Validate the input and build the `WagerTransaction` (reject externally submitted `OPENING`)
2. [ ] Calculate `payloadHash`
3. [ ] `INSERT ... ON CONFLICT (idempotency_key) DO NOTHING`
   - if it already existed: matching hash → **replay** (returns the stored result); different hash → **idempotency conflict`
4. [ ] (SQS input) insert the inbox record in the same transaction
5. [ ] `SELECT wallet ... FOR UPDATE`
6. [ ] Validate wallet, player, and currency
7. [ ] If it requires a reference: look up by `(providerId, referenceExternalTransactionId)`
   - not found → `PENDING_REFERENCE` + event, with `next_attempt_at`
   - found → apply `ReferencePolicy`
8. [ ] Apply to the aggregate (`debit`/`credit`) or none (LOSS), or `reject(code)`
9. [ ] Write the wallet, ledger, and transaction (with the observed result) and outbox events
10. [ ] Commit; return the result to the caller

#### Notes
- [ ] REJECTED transactions are also persisted, so replay returns the same rejection
- [ ] A violation of the “reverse once” index becomes `REFERENCE_ALREADY_REVERSED`, not a 500 error
- [ ] Connection/timeout errors become **transient errors** (and do not mark the transaction FAILED)
- [ ] No external publishing occurs inside the transaction (only write to the outbox)

#### Done When
- BET, WIN, LOSS, REFUND, and ROLLBACK work end to end against real PostgreSQL

## 3.4 Idempotency Under Race Conditions: Replay and Conflict

Labels: `concurrency` `tests`

#### Tasks
- [ ] Test: the same request twice sequentially → the second returns `idempotentReplay: true` with the **same balance** as the first
- [ ] Test: the same key with a different payload → conflict
- [ ] Test: **the same bet 50 times in parallel** (`Promise.all`) → exactly 1 debit and 49 replays
- [ ] Test: replaying a REJECTED transaction returns the same rejection
- [ ] Test: replaying a PENDING_REFERENCE transaction

#### Done When
- All tests pass, and the balance == ledger invariant checked at the end of each test

## 3.5 Required Scenario: 100.00 with Two Concurrent 80.00 Bets

Labels: `concurrency` `tests`

#### Tasks
- [ ] Test with real parallelism (two connections/transactions at the same time, with no mocks)
- [ ] Verify: exactly 1 PROCESSED, 1 REJECTED (`INSUFFICIENT_FUNDS`), final balance 20.00, exactly 1 DEBIT ledger entry
- [ ] Submit both again → nothing changes (replay)
- [ ] Test: different wallets processed in parallel do not block each other (measure concurrent execution)
- [ ] Run the test 20 consecutive times to detect flakiness

#### Done When
- It always passes, never “sometimes”

---

# 4 · HTTP API

_Section 9 endpoints with consistent status mapping._

## 4.1 Input Validation and HTTP Status Mapping

Labels: `api` `docs`

**Objective:** The provider decides whether to retry based only on the status, without reading the message.

#### Decide and Document (Suggested)
| Scenario | Status |
|---|---|
| created (wallet) | 201 |
| processed / replay | 200 (`idempotentReplay` no corpo) |
| accepted, awaiting reference | 202 |
| invalid payload | 400 |
| not found | 404 |
| idempotency conflict / duplicate wallet | 409 |
| business-rule rejection | 422 (with `failureCode` and `transactionId`) |
| transient infrastructure failure | 503 + `Retry-After` |

#### Tasks
- [ ] Input parser/validator (zod or valibot, or manual validation), converting it into the use-case command
- [ ] Global exception filter that maps domain/application errors → to a status and a standard body `{ code, message, ... }`
- [ ] Never expose a stack trace or SQL in the response
- [ ] Table in ARCHITECTURE.md

#### Done When
- The same error type returns the same status across all endpoints

## 4.2 Wallet endpoints: create, retrieve, and paginated ledger

Labels: `api`

#### Tasks
- [ ] `POST /wallets` → OpenWallet
- [ ] `GET /wallets/:walletId`
- [ ] `GET /wallets/:walletId/ledger?cursor=&limit=50`
  - **opaque and stable** cursor: base64url of `(created_at, id)` of the last item
  - maximum `limit`
  - response `{ items, nextCursor }`
- [ ] Responses with `Money` in the format `{ amount: "25.00", currency: "BRL" }`

#### Tests
- [ ] pagination traverses all entries without duplicates or gaps, even while inserts occur
- [ ] invalid cursor → 400

#### Done When
- All three endpoints have integration tests

## 4.3 Wagering Endpoints: Submit and Retrieve Transactions

Labels: `api` `concurrency`

#### Tasks
- [ ] `POST /wagering/transactions`
  - `Idempotency-Key` header **required** (missing → 400)
  - the header key is the source of truth
  - response `{ transactionId, status, balance, idempotentReplay }`
- [ ] `GET /wagering/transactions/:transactionId`
- [ ] `GET /providers/:providerId/wagering/transactions/:externalTransactionId`

#### Tests
- [ ] each `kind` via HTTP
- [ ] missing header → 400; conflict → 409; insufficient balance → 422; missing reference → 202

#### Done When
- Every scenario in the status table is covered by tests

## 4.4 Authentication: Documented Extension Point

Labels: `api` `docs`

**No points awarded.** Implement the minimum now; Keycloak is optional.

#### Tasks
- [ ] No-op `AuthGuard` applied to routes (except health)
- [ ] Port `ProviderIdentityPort` (identifies the authenticated provider) with an implementation that trusts the payload
- [ ] Even without authentication, validate in the domain that the message’s `providerId` matches the reference
- [ ] ARCHITECTURE.md: why it was not implemented and what design should be adopted (OIDC client credentials per provider, `providerId` derived from the token)

#### Done When
- Replacing the no-op guard with a real guard does not require changes to the use cases

---

# 5 · SQS Messaging

_FIFO queue consumer with inbox, post-commit acknowledgment, retries, and DLQ._

## 5.1 Study: SQS (FIFO, Visibility Timeout, DLQ)

Labels: `study` `messaging`

#### Topics
- [ ] Standard vs. FIFO; `MessageGroupId` (use `walletId`) and `MessageDeduplicationId`
- [ ] Why FIFO deduplication (5-minute window) **does not replace** the inbox
- [ ] Long polling (`WaitTimeSeconds`), `MaxNumberOfMessages`
- [ ] Visibility timeout, `ChangeMessageVisibility`, `ApproximateReceiveCount`
- [ ] `DeleteMessage` = ack
- [ ] Redrive policy and `maxReceiveCount` → DLQ
- [ ] SDK: `bun add @aws-sdk/client-sqs`

#### Done When
- You should be able to explain what happens if the process crashes between commit and `DeleteMessage`

## 5.2 SQS Consumer Reusing the Use Case

Labels: `messaging` `concurrency`

#### Tasks
- [ ] Polling loop as a Nest provider (starts in `onApplicationBootstrap`)
- [ ] Parse and validate the envelope `{ messageId, type, occurredAt, data }`; malformed message → DLQ (permanent error)
- [ ] Call **the same** `ProcessWagerTransaction` from the API, passing `messageId` to the inbox
- [ ] Inbox `(consumerName, messageId)` written in the same transaction; if it already existed → acknowledge without reprocessing
- [ ] `DeleteMessage` **only after commit**
- [ ] Classify errors:
  - business (REJECTED) → ack (terminal)
  - transient (database unavailable, timeout) → do not acknowledge; increase visibility timeout with backoff
  - permanent → leave it for the DLQ (or send it explicitly) and mark FAILED if appropriate
- [ ] Consumer concurrency configurable (N messages in parallel)
- [ ] Script/CLI for publishing test messages to the queue

#### Done When
- A BET submitted through the queue has the same effect as one submitted through the API, and resubmitting the message creates no duplicates

## 5.3 Graceful Shutdown (SIGTERM)

Labels: `messaging`

#### Tasks
- [ ] `app.enableShutdownHooks()`
- [ ] In `onModuleDestroy`/`beforeApplicationShutdown`: stop polling, wait for in-progress messages (with a timeout)
- [ ] Received messages that have not started → `ChangeMessageVisibility(0)` to return them to the queue
- [ ] Do the same for the workers (outbox, pending reference): finish the current batch
- [ ] Log the start and end of shutdown

#### Tests
- [ ] Send SIGTERM during processing → no message lost or duplicated

#### Done When
- `docker compose stop` leaves no inconsistent state

---

# 6 · Outbox and Workers

_Reliable event publishing and out-of-order reference reprocessing._

## 6.1 Outbox Publisher Worker (Multi-Instance)

Labels: `messaging` `concurrency`

#### Tasks
- [ ] Scheduled loop (configurable interval)
- [ ] Claim a batch: `SELECT ... WHERE published_at IS NULL AND next_attempt_at <= now() ORDER BY occurred_at LIMIT n FOR UPDATE SKIP LOCKED`
- [ ] Publish to the events queue (SQS) with `MessageDeduplicationId = eventId`
- [ ] Success → `markPublished`; error → `scheduleRetry` (backoff)
- [ ] Decide whether to claim and publish within the same transaction (safe lock while publishing) or a "lease" with `locked_until`. Document the trade-off
- [ ] Accept that duplicate publication may occur (at-least-once); the consumer deduplicates by `eventId`
- [ ] Metric for **outbox lag** (age of the oldest pending event)

#### Tests
- [ ] two publishers running simultaneously → each event published once (or a safe duplicate)
- [ ] commit → process crashes before publishing → another instance publishes it
- [ ] SQS unavailable → retry with backoff, without losing anything

#### Done When
- All three tests pass with real processes/instances

## 6.2 PENDING_REFERENCE Worker (Out-of-Order References)

Labels: `messaging` `concurrency`

#### Tasks
- [ ] Search for `PENDING_REFERENCE` transactions due with `FOR UPDATE SKIP LOCKED`
- [ ] Reprocess through the same use-case path (the wallet lock, etc.)
- [ ] Exponential backoff by attempt (`attempts`, `next_attempt_at`)
- [ ] Define and justify the limit (e.g. N attempts or an X-minute TTL)
- [ ] Retries exhausted → `REJECTED` with `REFERENCE_NOT_FOUND` + event `WagerTransactionRejected`
- [ ] (Optional) When processing a transaction, wake up pending transactions that reference it by setting `next_attempt_at` to zero

#### Tests
- [ ] ROLLBACK arrives before BET → it remains pending → BET arrives → ROLLBACK is applied
- [ ] REFUND whose reference never arrives → rejected after the limit
- [ ] two workers do not process the same pending transaction

#### Done When
- All three scenarios pass, and the limit is justified in ARCHITECTURE.md

---

# 7 · Operations and Observability

_Reconciliation, health checks, structured logging, and metrics._

## 7.1 Wallet Reconciliation

Labels: `api` `observability`

#### Tasks
- [ ] `POST /wallets/:walletId/reconciliation`
- [ ] Calculate the balance from the ledger (`SUM` with signs determined by direction in SQL, using `NUMERIC`)
- [ ] Compare it with the stored balance → `{ storedBalance, calculatedBalance, difference, consistent, checkedEntries }`
- [ ] Discrepancy: **do not correct it**; log it at `error` level, increment the metric, and flag it in the response
- [ ] Reuse as a test helper ("invariante final")

#### Done When
- Force a discrepancy in the database (by disabling the trigger in a test) it is detected and reported

## 7.2 Health Checks: Liveness and Readiness

Labels: `observability` `api`

#### Tasks
- [ ] `GET /health/live` → 200 if the process responds (without contacting dependencies)
- [ ] `GET /health/ready` → `SELECT 1` in PostgreSQL + `GetQueueAttributes` in SQS, with a short timeout; 503 if either check fails
- [ ] No authentication
- [ ] (Opcional) `@nestjs/terminus`
- [ ] Health check for the `app` service in Docker Compose using `/health/ready`

#### Done When
- Stopping PostgreSQL makes readiness return 503 while liveness remains 200

## 7.3 Structured Logs with correlationId

Labels: `observability`

#### Tasks
- [ ] Logger JSON (`pino` / `nestjs-pino`)
- [ ] Context per request/message with `AsyncLocalStorage` (or `nestjs-cls`): `correlationId`, `messageId`, `transactionId`, `walletId`, `providerId`
- [ ] `correlationId` comes from the header `X-Correlation-Id` or the message; if missing, it is generated; and propagated to outbox events
- [ ] `redact` for sensitive data; **do not** log the full financial payload
- [ ] Key logs: processed/rejected transaction, replay, conflito, retry, DLQ, reconciliation discrepancy

#### Done When
- A single `correlationId` makes it possible to trace a transaction from the API through event publication

## 7.4 Metrics (Prometheus)

Labels: `observability`

#### Tasks
- [ ] `bun add prom-client` and endpoint `GET /metrics`
- [ ] Minimum metrics:
  - `wager_transactions_total{status,kind}`
  - `idempotency_duplicates_total{source}` (replay/inbox)
  - `idempotency_conflicts_total`
  - `processing_retries_total{reason}`
  - `dlq_messages_total`
  - `lock_conflicts_total` (lock timeout/serialization)
  - `outbox_lag_seconds` (gauge)
  - `wager_processing_duration_seconds` (histogram)
  - `reconciliation_divergences_total`
- [ ] Watch cardinality: never use `walletId` as a label

#### Done When
- `/metrics` shows all these metrics after running the concurrency tests

---

# 8 · Integration and Chaos Testing

_Real PostgreSQL and SQS, multiple instances, and injected failures. Final invariant: balance == ledger._

## 8.1 Test Infrastructure: Real Database, LocalStack, and Helpers

Labels: `tests` `setup`

#### Tasks
- [ ] Separate the scripts: `test:unit` (only `src/**/*.spec.ts`), `test:integration`, `test:concurrency`
- [ ] Before the suite: apply migrations to the test database and create/clear the queues
- [ ] Between tests: `TRUNCATE` (remember the ledger trigger: use a test role or `session_replication_role`)
- [ ] Helpers: `createWallet()`, `submit()`, `sendToQueue()`, `waitUntil(cond, timeout)`
- [ ] Helper `assertLedgerInvariant(walletId)` called in `afterEach`
- [ ] Option: `testcontainers` to start PostgreSQL/LocalStack per suite instead of using Compose

#### Done When
- `bun run test:integration` runs from scratch with one command after `docker compose up`

## 8.2 Integration Tests: Atomicity, Inbox, Retry, DLQ, Restart

Labels: `tests` `messaging`

#### Scenarios
- [ ] **Atomicity**: failure injected after writing the ledger and before commit → wallet, ledger, inbox, and outbox contain no records
- [ ] **Inbox/redelivery**: the same SQS message delivered twice → 1 effect
- [ ] **Retry**: PostgreSQL temporarily unavailable → the message is retried and processed later
- [ ] **DLQ**: permanently invalid message → moves to the DLQ after `maxReceiveCount`
- [ ] **Concurrent publishers** on the same outbox
- [ ] **Recovery after restart**: stop the app mid-operation, start it again, and the final state remains consistent

#### Done When
- All pass using PostgreSQL and SQS (no mocks)

## 8.3 Tests with ≥ 3 Instances and Real Failures

Labels: `tests` `concurrency`

#### Tasks
- [ ] Start 3 application processes (`Bun.spawn` with different ports, or `docker compose up --scale app=3`)
- [ ] Generate distributed concurrent load across instances for the **same** wallet
- [ ] **Worker crashes between commit and acknowledgment**: test hook (ex.: env `CRASH_AFTER_COMMIT=1`) calls `process.exit` before `DeleteMessage`; the message returns and another instance acknowledges it (inbox)
- [ ] REFUND/ROLLBACK delivered before its reference, with different instances processing each message
- [ ] Restart the entire service and verify the consistency of everything wallets
- [ ] Run repeatedly to detect flakiness

#### Done When
- The balance == ledger invariant holds for every wallet at the end of each scenario

---

# 9 · Documentation and Portfolio

_README, ARCHITECTURE.md, and portfolio polish._

## 9.1 README.md

Labels: `docs`

#### Contents
- [ ] What the project is, written in your own words (without copying the company prompt)
- [ ] Technology stack and high-level diagram (Mermaid)
- [ ] Prerequisites and setup (`bun install`, `docker compose up -d`, migrations)
- [ ] All commands (`dev`, `test:unit`, `test:integration`, `test:concurrency`, `lint`, `typecheck`)
- [ ] `curl` examples for the endpoints and for publishing messages to the queue
- [ ] Link to ARCHITECTURE.md

#### Done When
- Anyone can clone it and run everything by following only the README

## 9.2 ARCHITECTURE.md: Decisions, Trade-offs, and Limitations

Labels: `docs`

#### Sections
- [ ] Priorities and boundaries (layers, modules, dependency rule)
- [ ] Money: decimal.js, `NUMERIC(20,2)`, string in the contract
- [ ] ORM and transaction strategy (MikroORM, records + mappers)
- [ ] Concurrency (strategy, justification, and hot wallet)
- [ ] Idempotency (key, hash algorithm, replay, conflict)
- [ ] Schema: constraint table and the invariant each constraint protects
- [ ] WagerTransaction state diagram
- [ ] Ledger and reconciliation
- [ ] Out-of-order references (backoff, limit)
- [ ] FailureCodes table
- [ ] HTTP status mapping
- [ ] Inbox, outbox, SQS, DLQ, shutdown
- [ ] Observability
- [ ] Authentication (decision)
- [ ] Adopted interpretations and known limitations

#### Done When
- Every decision answers “what,” “why,” and “what trade-off did I accept”

## 9.3 CI with GitHub Actions and Final Polish

Labels: `setup` `tests`

#### Tasks
- [ ] Workflow: `bun install --frozen-lockfile`, `typecheck`, `lint`, `test:unit`
- [ ] Integration job with `services:` for PostgreSQL and LocalStack (or Docker Compose) running `test:integration`
- [ ] CI badge in the README
- [ ] Description, topics, and README link on the GitHub repository
- [ ] Revisar commits/branches, create uma tag `v1.0.0`

#### Done When
- Green CI on `main`

---

# 10 · Optional Items

_Enhancements. Only after everything above is green._

## 10.1 Load Test (bun run test:load)

Labels: `optional` `tests`

#### Tasks
- [ ] Tool: k6, autocannon, or a script using Bun
- [ ] Scenarios: muitas wallets (distributed) x uma hot wallet
- [ ] Record the environment (machine, number of instances, pool), methodology, throughput, p50/p95/p99, error rate, lock conflicts and outbox lag
- [ ] Honest bottleneck analysis

## 10.2 Authentication with Keycloak or Zitadel

Labels: `optional` `api`

#### Tasks
- [ ] Service in Docker Compose with preconfigured realm/clients (import)
- [ ] Client credentials per provider; `providerId` extracted from the token
- [ ] Real guard validating JWTs (JWKS) in place of the no-op
- [ ] Reject when the `providerId` in the body differs from the token

## 10.3 OpenTelemetry and Dashboard

Labels: `optional` `observability`

#### Tasks
- [ ] HTTP traces → use case → SQL → SQS with OpenTelemetry
- [ ] Prometheus + Grafana in Docker Compose with a dashboard (status, latency, outbox lag, DLQ)

## 10.4 Double-Entry Ledger

Labels: `optional` `domain`

#### Tasks
- [ ] "House" account (house account) per currency
- [ ] Each transaction creates a debit in one account and a credit in another; global sum always zero
- [ ] Global reconciliation
