# Distributed Wagering Processor

A TypeScript service built with NestJS for developing distributed wagering workflows. The codebase is organized around wagering domains and separates domain, application, infrastructure, and presentation concerns.

## Requirements

- [Bun](https://bun.sh/)
- Node.js compatible with the installed NestJS version

## Getting started

Install dependencies:

```bash
bun install
```

Copy `.env.example` to `.env` and set the environment variables you need. The application listens on port `3000` by default; set `PORT` to use a different port.

Start the application in watch mode:

```bash
bun run dev
```

Other useful commands:

```bash
bun run start       # Start the application
bun run build       # Compile the application
```

## Project structure

```text
src/
  modules/              # Application-wide modules
    application/
    domain/
    infrastructure/
    presentation/
  shared/
    health/              # Health-check functionality
    outbox/              # Shared outbox functionality
    wallet/              # Wallet domain
    wager/               # Wager domain
```

Domain areas separate their code by layer:

- `domain/` — domain models and business rules
- `application/` — use cases and application workflows
- `infrastructure/` — persistence and external-system integrations
- `presentation/` — HTTP endpoints and other delivery interfaces

## Naming and language conventions

- Use English for documentation, code comments, and variable names.
- Use kebab-case for file names, with a suffix that describes the file's role. For example: `wallet.ts` and `open-wallet.use-case.ts`.
- Keep unit tests next to the file they cover, using the `.spec.ts` suffix. For example, `money.spec.ts` sits beside `money.ts`.
- Put integration tests under `test/`, grouped by purpose when useful, such as `test/integration/` and `test/concurrency/`.
- Use the commit prefixes `feat:`, `fix:`, `test:`, `chore:`, or `docs:`. For example: `feat: add wallet opening use case`.

## Tests and quality checks

Run the test suite:

```bash
bun run test
```

Run tests in watch mode:

```bash
bun run test:watch
```

Run type checking, linting, and formatting checks:

```bash
bun run typecheck
bun run lint
bun run format:check
```

Format source and test files:

```bash
bun run format
```
