#!/usr/bin/env bash
# Creates labels, milestones and issues for the roadmap, and optionally adds them to a GitHub Project.
#
# Usage:
#   gh auth login
#   gh auth refresh -s project            # only needed if you use PROJECT
#   PROJECT="Distributed Wagering Processor" ./criar-cards.sh
#
# Env vars:
#   REPO     owner/repo            (default: kisalto/distributed-wagering-processor)
#   PROJECT  Project title (Projects v2) to add the issues to (optional)
#   DRY_RUN  1 = only print what would be done
#
# Safe to re-run: existing labels are updated, existing milestones and issues (same title) are skipped.
set -euo pipefail

REPO="${REPO:-kisalto/distributed-wagering-processor}"
PROJECT="${PROJECT:-}"
DRY_RUN="${DRY_RUN:-0}"

command -v gh >/dev/null || { echo "GitHub CLI (gh) not found: https://cli.github.com" >&2; exit 1; }

run() {
  if [ "$DRY_RUN" = "1" ]; then printf '[dry-run]'; printf ' %q' "$@"; echo; else "$@"; fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ "$DRY_RUN" = "1" ]; then
  EXISTING_MILESTONES=""
  EXISTING_ISSUES=""
else
  EXISTING_MILESTONES="$(gh api "repos/$REPO/milestones?state=all&per_page=100" --paginate -q '.[].title')"
  EXISTING_ISSUES="$(gh issue list -R "$REPO" --state all --limit 1000 --json title -q '.[].title')"
fi

has_line() { printf '%s\n' "$2" | grep -Fxq -- "$1"; }

echo "==> Labels"

run gh label create estudo -R "$REPO" --color 0E8A16 --description 'Leitura/aprendizado antes de codar' --force
run gh label create setup -R "$REPO" --color BFD4F2 --description 'Ambiente, ferramentas, configuração' --force
run gh label create 'domínio' -R "$REPO" --color 5319E7 --description 'Domain layer (TS puro, sem banco/Nest)' --force
run gh label create 'persistência' -R "$REPO" --color 1D76DB --description 'PostgreSQL, MikroORM, migrations' --force
run gh label create 'concorrência' -R "$REPO" --color B60205 --description 'Locks, idempotência, corridas' --force
run gh label create api -R "$REPO" --color FBCA04 --description 'Endpoints HTTP' --force
run gh label create mensageria -R "$REPO" --color D93F0B --description 'SQS, inbox, outbox, workers' --force
run gh label create observabilidade -R "$REPO" --color C5DEF5 --description 'Logs, métricas, health' --force
run gh label create testes -R "$REPO" --color 0052CC --description 'Testes de integração e concorrência' --force
run gh label create docs -R "$REPO" --color FEF2C0 --description 'README, ARCHITECTURE.md' --force
run gh label create opcional -R "$REPO" --color EDEDED --description 'Diferencial, fazer só no fim' --force

echo "==> Milestones"
if has_line '0 · Setup e fundamentos' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'0 · Setup e fundamentos'; else run gh api "repos/$REPO/milestones" -f title='0 · Setup e fundamentos' -f description='Ambiente do zero, revisão de TypeScript, conceitos de DDD e de sistemas financeiros.' >/dev/null; fi
if has_line '1 · Domínio puro' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'1 · Domínio puro'; else run gh api "repos/$REPO/milestones" -f title='1 · Domínio puro' -f description='Modelo de domínio em TypeScript puro, sem NestJS e sem banco. Tudo com testes unitários (bun test).' >/dev/null; fi
if has_line '2 · Persistência' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'2 · Persistência'; else run gh api "repos/$REPO/milestones" -f title='2 · Persistência' -f description='PostgreSQL + MikroORM. O schema (constraints e índices) é avaliado diretamente.' >/dev/null; fi
if has_line '3 · Casos de uso e concorrência' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'3 · Casos de uso e concorrência'; else run gh api "repos/$REPO/milestones" -f title='3 · Casos de uso e concorrência' -f description='O coração do desafio: processar transações com correção sob concorrência e idempotência persistente.' >/dev/null; fi
if has_line '4 · API HTTP' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'4 · API HTTP'; else run gh api "repos/$REPO/milestones" -f title='4 · API HTTP' -f description='Endpoints da seção 9 com mapeamento de status consistente.' >/dev/null; fi
if has_line '5 · Mensageria SQS' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'5 · Mensageria SQS'; else run gh api "repos/$REPO/milestones" -f title='5 · Mensageria SQS' -f description='Consumer da fila FIFO com inbox, ack após commit, retry e DLQ.' >/dev/null; fi
if has_line '6 · Outbox e workers' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'6 · Outbox e workers'; else run gh api "repos/$REPO/milestones" -f title='6 · Outbox e workers' -f description='Publicação confiável de eventos e reprocessamento de referências fora de ordem.' >/dev/null; fi
if has_line '7 · Operação e observabilidade' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'7 · Operação e observabilidade'; else run gh api "repos/$REPO/milestones" -f title='7 · Operação e observabilidade' -f description='Reconciliação, health checks, logs estruturados e métricas.' >/dev/null; fi
if has_line '8 · Testes de integração e caos' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'8 · Testes de integração e caos'; else run gh api "repos/$REPO/milestones" -f title='8 · Testes de integração e caos' -f description='PostgreSQL e SQS reais, múltiplas instâncias, falhas injetadas. Invariante final: saldo == ledger.' >/dev/null; fi
if has_line '9 · Documentação e portfólio' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'9 · Documentação e portfólio'; else run gh api "repos/$REPO/milestones" -f title='9 · Documentação e portfólio' -f description='README, ARCHITECTURE.md e acabamento para o currículo.' >/dev/null; fi
if has_line '10 · Opcionais' "$EXISTING_MILESTONES"; then echo "  skip milestone: "'10 · Opcionais'; else run gh api "repos/$REPO/milestones" -f title='10 · Opcionais' -f description='Diferenciais. Só depois de tudo acima estar verde.' >/dev/null; fi

echo "==> Issues"
create_issue() {  # $1 title, $2 body file, $3 milestone, rest: labels
  local title="$1" body="$2" milestone="$3"; shift 3
  if has_line "$title" "$EXISTING_ISSUES"; then echo "  skip issue: $title"; return; fi
  local args=(issue create -R "$REPO" --title "$title" --body-file "$body" --milestone "$milestone")
  for l in "$@"; do args+=(--label "$l"); done
  if [ -n "$PROJECT" ]; then args+=(--project "$PROJECT"); fi
  run gh "${args[@]}"
}

# ---- 0 · Setup e fundamentos
cat > "$TMP/01.md" <<'__CARD_BODY__'
**Objetivo:** ter tudo instalado e funcionando antes de escrever código.

### Fazer
- [ ] Decidir onde rodar: Windows nativo ou **WSL2** (recomendado: WSL2, porque Docker, Bun e scripts shell se comportam igual ao Linux da CI)
- [ ] Instalar o **Bun 1.x**
  - Linux/WSL/macOS: `curl -fsSL https://bun.sh/install | bash`
  - Windows nativo: `powershell -c "irm bun.sh/install.ps1 | iex"`
- [ ] Instalar **Docker** (Docker Desktop com backend WSL2, ou Docker Engine no Linux) e conferir `docker compose version`
- [ ] Instalar/atualizar **git** e o **GitHub CLI** (`gh auth login`)
- [ ] VS Code + extensões: ESLint ou oxc, Prettier, Docker, PostgreSQL (ou DBeaver), "Pretty TypeScript Errors"
- [ ] Conferir versões: `bun --version`, `docker --version`, `git --version`
- [ ] Limpar o repo: apagar tudo menos o README e fazer o commit `chore: reset project`

### Pronto quando
- `bun --version` mostra 1.x e `docker run hello-world` funciona
__CARD_BODY__
create_issue '0.1 Preparar o ambiente de desenvolvimento' "$TMP/01.md" '0 · Setup e fundamentos' setup
cat > "$TMP/02.md" <<'__CARD_BODY__'
**Objetivo:** reaprender só o TS que vai aparecer no projeto. Faça os exercícios num arquivo solto (`scratch/ts.ts`) e rode com `bun run scratch/ts.ts`.

### Tópicos
- [ ] `type` x `interface`: quando usar cada um (interface para DTO/props, type para unions)
- [ ] Union types e literal types (`'BET' | 'WIN'`) x `enum`: prós e contras
- [ ] Classes: `private`, `protected`, `readonly`, `public`, parameter properties no construtor
- [ ] **Construtor privado + factories estáticas** (`static create()`, `static rehydrate()`), padrão central do desafio
- [ ] Getters (`get balance()`) e por que expor estado só por eles
- [ ] Erros customizados: `class InsufficientFundsError extends Error`, com a propriedade `code`
- [ ] `unknown` x `any`, narrowing (`typeof`, `instanceof`, discriminated unions)
- [ ] Generics básicos (`IntegrationEvent<T>`, `Readonly<T>`, `Record<K, V>`)
- [ ] `import`/`export`, `import type`
- [ ] `async`/`await` e `Promise<T>`
- [ ] Opções do `tsconfig` que vamos usar: `strict`, `noUncheckedIndexedAccess`, `experimentalDecorators`, `emitDecoratorMetadata`
- [ ] Decorators: o que são e como o NestJS os usa (só o conceito)

### Exercício
- [ ] Escrever uma classe `Temperature` imutável, com construtor privado, `static fromCelsius()`, `add()` que retorna nova instância, erro customizado para valor inválido e 3 testes com `bun test`

### Pronto quando
- Você consegue explicar por que `private constructor` + `static create()` protege invariantes
__CARD_BODY__
create_issue '0.2 Estudo: revisão de TypeScript (o necessário para o projeto)' "$TMP/02.md" '0 · Setup e fundamentos' estudo
cat > "$TMP/03.md" <<'__CARD_BODY__'
**Objetivo:** entender o vocabulário antes de modelar. Anote com suas palavras, porque isso vira base do ARCHITECTURE.md.

### Tópicos
- [ ] **Value Object**: imutável, igualdade por valor (ex.: `Money`)
- [ ] **Entity**: identidade própria, estado muda ao longo do tempo (ex.: `WagerTransaction`)
- [ ] **Aggregate / Aggregate Root**: fronteira de consistência; só se altera pelo root (ex.: `Wallet`)
- [ ] **Invariantes** e onde elas vivem (no domínio **e** no schema do banco)
- [ ] **Domain Events** x **Integration Events**
- [ ] **Repository** como porta (interface em `application`, implementação em `infrastructure`)
- [ ] Camadas: `domain` → `application` (use cases + ports) → `infrastructure` (adapters) → `presentation` (HTTP/SQS)
- [ ] Regra de dependência: domain não importa NestJS, MikroORM nem nada de infra
- [ ] `create` x `rehydrate`: criar valida regras; reidratar só reconstrói o que já foi persistido

### Material sugerido
- "Domain-Driven Design Distilled" (Vaughn Vernon), capítulos de Aggregates e Value Objects
- Artigo "Hexagonal Architecture" (Alistair Cockburn)

### Pronto quando
- Você consegue desenhar num papel quem chama quem: Controller → UseCase → Port ← Adapter
__CARD_BODY__
create_issue '0.3 Estudo: DDD tático e arquitetura hexagonal' "$TMP/03.md" '0 · Setup e fundamentos' estudo
cat > "$TMP/04.md" <<'__CARD_BODY__'
**Objetivo:** entender os problemas que o desafio avalia antes de ver código.

### Tópicos
- [ ] Por que `0.1 + 0.2 !== 0.3`: ponto flutuante e por que dinheiro nunca é `number`
- [ ] Decimal de precisão arbitrária (`decimal.js`) e `NUMERIC(p,s)` no Postgres
- [ ] Arredondamento bancário (`ROUND_HALF_EVEN`) e escala fixa de 2 casas
- [ ] **Ledger**: registro imutável (append-only); o saldo é uma *materialização* do ledger
- [ ] Reconciliação: soma do ledger == saldo armazenado
- [ ] (Opcional) double-entry bookkeeping
- [ ] **Entrega at-least-once**: a mesma mensagem pode chegar 2+ vezes, fora de ordem
- [ ] **Idempotência**: idempotency key + hash do payload; "replay" x "conflito"
- [ ] **Lost update** e race condition: o problema do read → calculate → update
- [ ] **Transactional Outbox** e **Inbox**: por que existem e qual problema resolvem (dual write)

### Material sugerido
- "Designing Data-Intensive Applications", cap. 7 (Transactions)
- microservices.io → Transactional Outbox, Idempotent Consumer
- Stripe Engineering → "Designing robust and predictable APIs with idempotency"

### Pronto quando
- Você consegue explicar o cenário "duas apostas de 80 com saldo 100" e por que ele quebra sem lock
__CARD_BODY__
create_issue '0.4 Estudo: dinheiro, ledger, idempotência e entrega at-least-once' "$TMP/04.md" '0 · Setup e fundamentos' estudo
cat > "$TMP/05.md" <<'__CARD_BODY__'
**Objetivo:** esqueleto rodando com Bun, TS strict e `bun test`.

### Fazer
- [ ] Gerar o projeto sem instalar dependências:
  `bunx @nestjs/cli new . --skip-git --skip-install --package-manager npm`
- [ ] `bun install` (vai gerar o `bun.lock`)
- [ ] Remover Jest: `@types/jest`, `jest`, `ts-jest`, a seção `jest` do package.json e os scripts `test:*` do Jest
- [ ] `bun add -d @types/bun` e ajustar `types` no tsconfig
- [ ] Converter o teste de exemplo para `import { describe, it, expect } from 'bun:test'`
- [ ] tsconfig: `strict: true`, `noUncheckedIndexedAccess: true`, `noImplicitOverride: true`, `experimentalDecorators` e `emitDecoratorMetadata` ligados
- [ ] Scripts no package.json: `dev` (`bun --watch src/main.ts`), `start`, `test`, `typecheck` (`tsc --noEmit`), `lint`, `format`
- [ ] Prettier + lint (oxlint ou ESLint), escolha um
- [ ] Atualizar `.gitignore` (node_modules, dist, .env, coverage)
- [ ] Criar `.env.example`
- [ ] Ajustar `name` no package.json para `distributed-wagering-processor`

### Pronto quando
- `bun run dev` sobe o Nest e `curl localhost:3000` responde
- `bun test` e `bun run typecheck` passam
__CARD_BODY__
create_issue '0.5 Criar o projeto NestJS com Bun' "$TMP/05.md" '0 · Setup e fundamentos' setup
cat > "$TMP/06.md" <<'__CARD_BODY__'
**Objetivo:** decidir agora para não ficar mudando depois.

### Estrutura sugerida
```
src/
  shared/          # Money, IntegrationEvent, OutboxMessage, ports genéricas (Clock, IdGenerator)
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

### Fazer
- [ ] Criar as pastas (vazias, com `.gitkeep`)
- [ ] Convenção de arquivos: `kebab-case` + sufixo do papel (`wallet.ts`, `open-wallet.use-case.ts`, `wallet.repository.ts`, `wallet.record.ts`, `wallet.controller.ts`)
- [ ] Testes unitários ao lado do arquivo (`money.spec.ts`); integração em `test/`
- [ ] Comentários de código em inglês
- [ ] Padrão de commits (Conventional Commits: `feat:`, `fix:`, `test:`, `chore:`, `docs:`)
- [ ] Escrever essas decisões numa seção curta do README

### Pronto quando
- Estrutura commitada e convenções documentadas
__CARD_BODY__
create_issue '0.6 Definir estrutura de pastas e convenções' "$TMP/06.md" '0 · Setup e fundamentos' setup docs
cat > "$TMP/07.md" <<'__CARD_BODY__'
**Objetivo:** subir a infraestrutura local com um comando.

### Fazer
- [ ] `docker-compose.yml` com:
  - `postgres:16-alpine`, volume, healthcheck (`pg_isready -U $DB_USER -d $DB_NAME`)
  - `localstack/localstack` com `SERVICES=sqs`, healthcheck e o init script montado em `/etc/localstack/init/ready.d/`
  - Se o LocalStack exigir token/conta na versão atual, use **MiniStack**, que o enunciado também aceita
- [ ] Script `docker/localstack/init-queues.sh` (use `awslocal`):
  - criar `wager-transactions-dlq.fifo` (`FifoQueue=true`)
  - criar `wager-transactions.fifo` com `FifoQueue=true`, `VisibilityTimeout`, e `RedrivePolicy` apontando para a DLQ com `maxReceiveCount` (ex.: 5)
  - criar uma fila/tópico para os eventos publicados pela outbox (ex.: `wager-events.fifo`)
- [ ] Não usar `container_name` fixo (atrapalha subir várias instâncias)
- [ ] Remover `version:` (obsoleto)
- [ ] `.env.example` com `DB_*`, `AWS_ENDPOINT_URL`, `AWS_REGION`, `AWS_ACCESS_KEY_ID=test`, `AWS_SECRET_ACCESS_KEY=test`, URLs das filas
- [ ] Banco separado para testes (ex.: `wager_test`), criado por um init SQL do Postgres

### Pronto quando
- `docker compose up -d` deixa os dois serviços *healthy*
- `awslocal sqs list-queues` (ou `aws --endpoint-url ...`) mostra as 3 filas
__CARD_BODY__
create_issue '0.7 Docker Compose: PostgreSQL + LocalStack (SQS)' "$TMP/07.md" '0 · Setup e fundamentos' setup mensageria

# ---- 1 · Domínio puro
cat > "$TMP/08.md" <<'__CARD_BODY__'
**Objetivo:** o tijolo mais importante. Sem `number` em lugar nenhum.

### Fazer
- [ ] `bun add decimal.js`
- [ ] `Decimal.clone({ rounding: ROUND_HALF_EVEN, ... })` próprio, para não mexer na config global
- [ ] Interface `MoneyProps { amount: string; currency: string }`
- [ ] `private constructor`, `static from(props)`, `static zero(currency)`
- [ ] Validação por regex: só `^\d+\.\d{2}$` (sem negativo, sem notação científica, sem espaços, exatamente 2 casas)
- [ ] `add`, `subtract`, `negate` (retornam nova instância)
- [ ] `isZero`, `isPositive`, `isNegative`, `isLessThan`, `equals`
- [ ] `toString()` sempre com 2 casas; `toJSON()` retorna `MoneyProps`
- [ ] `assertSameCurrency` lança `CurrencyMismatchError`
- [ ] Moedas ISO-4217 suportadas (BRL obrigatório; mantenha o modelo multi-moeda)
- [ ] Limite máximo compatível com a coluna `NUMERIC` que você vai usar
- [ ] Normalizar `-0.00` para `0.00`
- [ ] Erros de domínio com `code` estável

### Testes
- [ ] aceita `"25.00"`, `"0.00"`
- [ ] rejeita `""`, `"25"`, `"25.5"`, `"25.001"`, `"-1.00"`, `"1e3"`, `"NaN"`, `"Infinity"`, `" 25.00"`, `"01.00"`
- [ ] `0.10 + 0.20 == 0.30`
- [ ] subtract, negate, comparações
- [ ] **conflito de moeda** em add/subtract/isLessThan/equals
- [ ] moeda inválida
- [ ] overflow do limite
- [ ] imutabilidade (operação não altera a instância original)
- [ ] `toJSON()` produz o formato do contrato

### Pronto quando
- Testes verdes e zero `number` representando valor monetário
__CARD_BODY__
create_issue '1.1 Money (value object) + testes' "$TMP/08.md" '1 · Domínio puro' 'domínio'
cat > "$TMP/09.md" <<'__CARD_BODY__'
**Objetivo:** todo motivo de rejeição tem um código estável, legível por máquina, e o provedor sabe se deve reenviar, corrigir ou desistir.

### Fazer
- [ ] `FailureCode` (union de string literals ou enum). Sugestão inicial:
  - `INSUFFICIENT_FUNDS`: BET sem saldo
  - `REVERSAL_INSUFFICIENT_FUNDS`: ROLLBACK de WIN deixaria saldo negativo (**diferente** do anterior, como o enunciado exige)
  - `WALLET_NOT_FOUND`, `WALLET_PLAYER_MISMATCH`, `CURRENCY_MISMATCH`
  - `REFERENCE_NOT_FOUND`: esgotou tentativas de PENDING_REFERENCE
  - `REFERENCE_MISMATCH`: provider/player/wallet/moeda/rodada diferentes
  - `REFERENCE_INVALID_KIND`: REFUND de algo que não é BET etc.
  - `REFERENCE_NOT_PROCESSED`
  - `REFERENCE_ALREADY_REVERSED`
  - `AMOUNT_MISMATCH`: valor diferente da referência
- [ ] Para cada código: categoria (`business` / `permanent` / `transient`) e ação do provedor (`do_not_retry`, `fix_payload`, `retry`)
- [ ] Classe base `DomainError` com `code`, e as subclasses
- [ ] Erro de programação separado: `InvalidTransactionStateError` (transição a partir de estado terminal)
- [ ] Tabela no ARCHITECTURE.md

### Pronto quando
- Tabela de códigos documentada e erros usados nos próximos cards
__CARD_BODY__
create_issue '1.2 Erros de domínio e taxonomia de FailureCode' "$TMP/09.md" '1 · Domínio puro' 'domínio' docs
cat > "$TMP/10.md" <<'__CARD_BODY__'
**Objetivo:** lançamento contábil imutável por estrutura (sem setters, sem métodos de transição).

### Fazer
- [ ] `enum LedgerDirection { Debit = 'DEBIT', Credit = 'CREDIT' }`
- [ ] Campos `readonly`: `id`, `walletId`, `transactionId`, `direction`, `money`, `balanceBefore`, `balanceAfter`, `createdAt`
- [ ] `static create(props)` valida:
  - `money` positivo
  - mesma moeda em tudo
  - `balanceBefore ± money === balanceAfter`
  - `balanceAfter` não negativo
- [ ] `static rehydrate(state)` sem revalidar
- [ ] `isBalanced()`

### Testes
- [ ] crédito e débito válidos
- [ ] aritmética errada lança erro
- [ ] moeda diferente lança erro
- [ ] valor zero/negativo lança erro

### Pronto quando
- Não existe forma (sem cast) de alterar um lançamento depois de criado
__CARD_BODY__
create_issue '1.3 WalletLedgerEntry (imutável) + testes' "$TMP/10.md" '1 · Domínio puro' 'domínio'
cat > "$TMP/11.md" <<'__CARD_BODY__'
**Objetivo:** saldo e ledger nascem juntos, então é impossível mudar saldo sem lançamento.

### Fazer
- [ ] `private constructor` com `id`, `playerId`, `currency`, `_balance`, `_version`, `createdAt`, `_updatedAt`
- [ ] `static open({ id, playerId, initialBalance })`: `version = 1`
- [ ] `static rehydrate(state)`
- [ ] Getters `balance`, `version`, `updatedAt`
- [ ] `debit(money, transactionId, at)` → retorna `WalletLedgerEntry`; lança `InsufficientFundsError` se ficar negativo
- [ ] `credit(money, transactionId, at)` → retorna `WalletLedgerEntry`
- [ ] Cada movimentação incrementa `version` **só quando o saldo muda**
- [ ] `assertSameCurrency`
- [ ] Decidir: a abertura com saldo > 0 gera o lançamento OPENING aqui ou no use case? Documentar

### Testes
- [ ] abrir com saldo zero e com saldo positivo
- [ ] débito com saldo suficiente / exato / insuficiente
- [ ] crédito
- [ ] version começa em 1 e incrementa
- [ ] moeda diferente
- [ ] `balanceBefore`/`balanceAfter` do lançamento retornado batem com a wallet

### Pronto quando
- Os invariantes de saldo da seção 6.2 estão cobertos por teste
__CARD_BODY__
create_issue '1.4 Wallet (aggregate root) + testes' "$TMP/11.md" '1 · Domínio puro' 'domínio'
cat > "$TMP/12.md" <<'__CARD_BODY__'
**Objetivo:** estados e transições explícitos; estados terminais nunca mudam.

### Fazer
- [ ] Enums `WagerTransactionKind` (OPENING, BET, WIN, LOSS, REFUND, ROLLBACK) e `WagerTransactionStatus` (PENDING, PENDING_REFERENCE, PROCESSED, REJECTED, FAILED)
- [ ] `static create(props)`: nasce em `PENDING`; valida que REFUND/ROLLBACK têm `referenceExternalTransactionId`
- [ ] `static createOpening(...)` interno, para o OPENING não passar pelo caminho público
- [ ] `static rehydrate(state)`
- [ ] Transições: `markProcessed(refId, at)`, `markPendingReference()`, `reject(code)`, `fail(code)`
- [ ] Qualquer transição a partir de terminal → `InvalidTransactionStateError`
- [ ] Consultas: `isTerminal()`, `affectsBalance()` (false para LOSS), `requiresReference()`, `matchesPayload(hash)`, `ledgerDirectionFor(reference?)`
- [ ] Campo para o **resultado observado** (ex.: `balanceAfter` no momento do processamento), necessário para o replay devolver o saldo original
- [ ] Desenhar o diagrama de estados (Mermaid) para o ARCHITECTURE.md

### Testes
- [ ] todas as transições válidas
- [ ] todas as transições a partir de terminal lançam erro
- [ ] REFUND/ROLLBACK sem referência são rejeitados no `create`
- [ ] `ledgerDirectionFor`: BET→DEBIT, WIN/REFUND→CREDIT, ROLLBACK→inverso da referência
- [ ] `matchesPayload` com hash igual/diferente

### Pronto quando
- Diagrama de estados documentado e 100% das transições testadas
__CARD_BODY__
create_issue '1.5 WagerTransaction (máquina de estados) + testes' "$TMP/12.md" '1 · Domínio puro' 'domínio'
cat > "$TMP/13.md" <<'__CARD_BODY__'
**Objetivo:** concentrar as regras da seção 7 num lugar só, testável sem banco.

### Fazer
- [ ] Criar uma função ou classe (ex.: `ReferencePolicy`) que recebe a transação nova e a referência e retorna ok ou `FailureCode`
- [ ] A referência deve ter o mesmo provider, player, wallet, moeda e **rodada**
- [ ] REFUND só referencia BET; ROLLBACK referencia BET, WIN ou REFUND
- [ ] A referência precisa estar PROCESSED
- [ ] O valor deve ser igual ao da referência (sem reversão parcial)
- [ ] Já revertida pelo mesmo tipo → `REFERENCE_ALREADY_REVERSED` (a garantia real vem do índice único no banco; aqui é só a checagem de domínio)
- [ ] WIN pode referenciar a BET da mesma rodada (opcional; documente sua interpretação)
- [ ] Ao aplicar, reversão que deixaria saldo negativo → `REVERSAL_INSUFFICIENT_FUNDS`

### Testes (um por regra)
- [ ] BET / WIN / LOSS / REFUND / ROLLBACK: caminho feliz
- [ ] cada violação retorna o código certo
- [ ] ROLLBACK de WIN com saldo insuficiente

### Pronto quando
- Cada linha da tabela da seção 7 tem pelo menos um teste
__CARD_BODY__
create_issue '1.6 Regras de referência e reversão (domain service) + testes' "$TMP/13.md" '1 · Domínio puro' 'domínio'
cat > "$TMP/14.md" <<'__CARD_BODY__'
**Objetivo:** mesmo conteúdo de negócio → mesmo hash, independente da ordem das chaves.

### Fazer
- [ ] Definir o **subconjunto de campos de negócio** que entra no hash (providerId, externalTransactionId, playerId, walletId, roundId, gameId, kind, money, referenceExternalTransactionId)
- [ ] Fora do hash: header, messageId, occurredAt e outros metadados de transporte
- [ ] JSON canônico: chaves ordenadas recursivamente, sem espaços; `undefined` omitido
- [ ] `sha256` em hex (`Bun.CryptoHasher` ou `node:crypto`)
- [ ] Porta `PayloadHasher` em application, implementação em infrastructure
- [ ] Documentar o algoritmo no ARCHITECTURE.md

### Testes
- [ ] mesma informação em ordem diferente → mesmo hash
- [ ] valor diferente → hash diferente
- [ ] metadados de transporte não mudam o hash

### Pronto quando
- Algoritmo documentado e testado
__CARD_BODY__
create_issue '1.7 Hash canônico do payload (idempotência) + testes' "$TMP/14.md" '1 · Domínio puro' 'domínio' 'concorrência'
cat > "$TMP/15.md" <<'__CARD_BODY__'
**Objetivo:** eventos tipados, com `eventType` e `version` fixos no tipo.

### Fazer
- [ ] `abstract class IntegrationEvent<T>` com `eventId`, `aggregateId`, `correlationId`, `causationId?`, `occurredAt`, `data`, `abstract eventType`, `abstract version`, `toJSON()`
- [ ] Subclasses com `static from(...)`:
  - `WagerTransactionProcessed` (inclusive LOSS)
  - `WagerTransactionRejected`
  - `WalletBalanceChanged` (só quando o saldo muda)
  - `WagerTransactionPendingReference`
- [ ] `data` usa `MoneyProps` (string), nunca a instância de `Money`
- [ ] `occurredAt` serializado em ISO-8601

### Testes
- [ ] `toJSON()` de cada evento tem o formato do envelope
- [ ] `JSON.parse(JSON.stringify(evt.toJSON()))` é estável

### Pronto quando
- Os 4 eventos existem e serializam corretamente
__CARD_BODY__
create_issue '1.8 IntegrationEvent + eventos concretos' "$TMP/15.md" '1 · Domínio puro' 'domínio' mensageria
cat > "$TMP/16.md" <<'__CARD_BODY__'
**Objetivo:** modelos de dedup de entrada e publicação confiável de saída.

### Fazer
- [ ] `InboxMessage.receive({ messageId, consumerName, payloadHash, receivedAt })`, `rehydrate`, `isProcessed`, `markProcessed(at)`
- [ ] `OutboxMessage.enqueue(event)`, `rehydrate`, `isPending`, `isDue(now)`, `markPublished(at)`, `scheduleRetry(now)`
- [ ] Backoff exponencial com teto e jitter em `scheduleRetry` (ex.: `min(base * 2^attempts, max)`)
- [ ] Porta `Clock` para os testes controlarem o tempo

### Testes
- [ ] `scheduleRetry` incrementa `attempts` e empurra `nextAttemptAt`
- [ ] `isDue` antes/depois do horário
- [ ] `markPublished` torna `isPending()` falso

### Pronto quando
- Os dois modelos testados, com o tempo controlado por `Clock`
__CARD_BODY__
create_issue '1.9 InboxMessage e OutboxMessage + testes' "$TMP/16.md" '1 · Domínio puro' 'domínio' mensageria

# ---- 2 · Persistência
cat > "$TMP/17.md" <<'__CARD_BODY__'
**Objetivo:** entender a ferramenta antes de mapear.

### Tópicos
- [ ] EntityManager, **Unit of Work**, **Identity Map**, `em.fork()` por request
- [ ] `em.transactional(async (em) => ...)`
- [ ] `LockMode.PESSIMISTIC_WRITE` (= `SELECT ... FOR UPDATE`) e `LockMode.OPTIMISTIC`
- [ ] `EntitySchema` / `defineEntity` x decorators. Para manter o domínio sem dependência do ORM, use **records separados + mappers**
- [ ] Migrations: `up`/`down`, SQL na mão com `this.addSql()` (necessário para CHECK, índice parcial, trigger)
- [ ] Postgres: `NUMERIC(20,2)`, `CHECK`, `UNIQUE`, índice parcial, `ON CONFLICT DO NOTHING`, triggers
- [ ] Níveis de isolamento (READ COMMITTED x REPEATABLE READ x SERIALIZABLE)

### Pronto quando
- Você sabe explicar por que o domínio não usa `@Entity()` direto
__CARD_BODY__
create_issue '2.1 Estudo: MikroORM e transações no PostgreSQL' "$TMP/17.md" '2 · Persistência' estudo 'persistência'
cat > "$TMP/18.md" <<'__CARD_BODY__'
### Fazer
- [ ] `bun add @mikro-orm/core @mikro-orm/postgresql @mikro-orm/nestjs @mikro-orm/migrations`
- [ ] `bun add -d @mikro-orm/cli`
- [ ] **Uma única** config (`mikro-orm.config.ts`) usada pelo Nest e pelo CLI, sem duplicar
- [ ] Ler variáveis de ambiente com validação (falhar no boot se faltar)
- [ ] Apontar `entities` para os seus records (`*.record.ts`)
- [ ] Configurar o CLI para rodar TS com Bun (ver a doc da versão instalada; testar `bunx mikro-orm debug`)
- [ ] Pool de conexões dimensionado e documentado
- [ ] Scripts: `db:migrate`, `db:migrate:down`, `db:migration:create`

### Pronto quando
- `bunx mikro-orm debug` encontra o banco e as entidades
__CARD_BODY__
create_issue '2.2 Configurar MikroORM no Nest e no CLI' "$TMP/18.md" '2 · Persistência' 'persistência' setup
cat > "$TMP/19.md" <<'__CARD_BODY__'
**Objetivo:** as invariantes vivem no banco, não só no código.

### `wallets`
- [ ] `amount NUMERIC(20,2)`, `currency CHAR(3)`
- [ ] `UNIQUE (player_id, currency)`
- [ ] `CHECK (balance_amount >= 0)`, `CHECK (version >= 1)`

### `wager_transactions`
- [ ] `UNIQUE (idempotency_key)`
- [ ] `UNIQUE (provider_id, external_transaction_id)`
- [ ] `CHECK` de `kind` e `status` válidos
- [ ] `CHECK (amount > 0)`
- [ ] `CHECK (kind NOT IN ('REFUND','ROLLBACK') OR reference_external_transaction_id IS NOT NULL)`
- [ ] `CHECK (status NOT IN ('REJECTED','FAILED') OR failure_code IS NOT NULL)`
- [ ] **Índice único parcial** que garante "reverter uma vez": `(reference_transaction_id, kind) WHERE status = 'PROCESSED' AND kind IN ('REFUND','ROLLBACK')`
- [ ] Índice para o worker: `(status, next_attempt_at) WHERE status = 'PENDING_REFERENCE'`
- [ ] Colunas do resultado observado (saldo após) para o replay

### `wallet_ledger_entries`
- [ ] FK para wallet e transaction
- [ ] `UNIQUE (transaction_id, wallet_id)`: no máximo um lançamento por transação por wallet
- [ ] `CHECK (amount > 0)`, `CHECK (balance_after >= 0)`
- [ ] `CHECK` da aritmética (CREDIT: after = before + amount; DEBIT: after = before - amount)
- [ ] **Trigger** `BEFORE UPDATE OR DELETE` que lança exceção (append-only)
- [ ] Índice `(wallet_id, created_at, id)` para paginação por cursor

### `inbox_messages`
- [ ] `PRIMARY KEY (consumer_name, message_id)`

### `outbox_messages`
- [ ] `payload JSONB`, `attempts`, `next_attempt_at`, `published_at`
- [ ] Índice parcial `(next_attempt_at) WHERE published_at IS NULL`

### Geral
- [ ] `down` funcional (reversível)
- [ ] Testar `up` → `down` → `up`

### Pronto quando
- A migration sobe e desce limpa, e cada constraint tem um motivo anotado
__CARD_BODY__
create_issue '2.3 Migration inicial com todas as constraints' "$TMP/19.md" '2 · Persistência' 'persistência' 'concorrência'
cat > "$TMP/20.md" <<'__CARD_BODY__'
**Objetivo:** o domínio continua puro; a infraestrutura traduz.

### Fazer
- [ ] Records do ORM (`wallet.record.ts` etc.) separados das classes de domínio
- [ ] Mappers `toDomain()` (usa `rehydrate`) e `toRecord()`
- [ ] Money ↔ `NUMERIC` sempre como **string** (configurar o driver `pg` para não converter numeric em number)
- [ ] Ports em `application/ports`:
  - `WalletRepository`: `findById`, `findByIdForUpdate` (lock), `save`
  - `WagerTransactionRepository`: `insertIfAbsent`, `findByIdempotencyKey`, `findByExternalId`, `save`, `findDuePendingReferences`
  - `LedgerRepository`: `append`, `listByWallet(cursor, limit)`, `sumByWallet`
  - `OutboxRepository`: `add`, `claimDue(limit)` (SKIP LOCKED), `save`
  - `InboxRepository`: `insertIfAbsent`
- [ ] Adapters em `infrastructure/persistence`
- [ ] Injeção via tokens do Nest (`provide: WALLET_REPOSITORY`)

### Pronto quando
- Nenhum arquivo em `domain/` importa algo do MikroORM ou do Nest
__CARD_BODY__
create_issue '2.4 Records, mappers e repositórios (ports + adapters)' "$TMP/20.md" '2 · Persistência' 'persistência' 'domínio'
cat > "$TMP/21.md" <<'__CARD_BODY__'
**Objetivo:** provar que o banco recusa estados inválidos mesmo se o código falhar.

### Fazer
- [ ] Helper que aplica as migrations no banco de teste e limpa as tabelas entre testes
- [ ] Teste que tenta violar **cada** constraint com SQL cru e espera erro:
  - wallet duplicada (player + moeda)
  - saldo negativo
  - idempotency key duplicada
  - dois ROLLBACKs PROCESSED para a mesma referência
  - `UPDATE`/`DELETE` em ledger
  - lançamento com aritmética errada
  - inbox duplicada
- [ ] Teste `up` → `down` → `up`

### Pronto quando
- Cada constraint tem um teste vermelho → verde
__CARD_BODY__
create_issue '2.5 Testes de integração: migrations e constraints' "$TMP/21.md" '2 · Persistência' testes 'persistência'

# ---- 3 · Casos de uso e concorrência
cat > "$TMP/22.md" <<'__CARD_BODY__'
### Tópicos
- [ ] Lock pessimista (`SELECT ... FOR UPDATE`) por wallet
- [ ] Optimistic locking (`version`) com retry limitado
- [ ] Update atômico condicionado (`UPDATE ... SET balance = balance - $1 WHERE id = $2 AND balance >= $1`)
- [ ] Deadlocks: ordem consistente de locks
- [ ] Hot wallet: o que acontece com cada estratégia quando 1 wallet recebe muita carga
- [ ] Por que lock global e lock em memória estão proibidos (múltiplas instâncias)

### Decidir e documentar
- [ ] Estratégia escolhida (sugestão: **pessimista por wallet**, mais `version` como defesa extra), com justificativa e trade-offs no ARCHITECTURE.md
- [ ] Timeout de lock (`lock_timeout`) e o que fazer quando estoura (erro transitório)

### Pronto quando
- Seção "Concorrência" do ARCHITECTURE.md escrita
__CARD_BODY__
create_issue '3.1 Estudo: estratégias de concorrência e decisão documentada' "$TMP/22.md" '3 · Casos de uso e concorrência' estudo 'concorrência'
cat > "$TMP/23.md" <<'__CARD_BODY__'
### Fazer
- [ ] Numa transação: criar a wallet; se o saldo inicial for > 0, criar a transação interna `OPENING` (PROCESSED) e o lançamento CREDIT; criar os eventos na outbox
- [ ] Wallet duplicada (violação de `UNIQUE(player_id, currency)`) → erro de conflito
- [ ] Ids via porta `IdGenerator` (UUID v7 é uma boa escolha: ordenável)

### Testes (integração)
- [ ] abre com saldo 0 → sem lançamento
- [ ] abre com 1000.00 → 1 OPENING + 1 CREDIT, saldo == ledger
- [ ] duplicada → conflito

### Pronto quando
- Invariante saldo == ledger vale logo após a abertura
__CARD_BODY__
create_issue '3.2 Use case: OpenWallet' "$TMP/23.md" '3 · Casos de uso e concorrência' 'domínio' 'persistência'
cat > "$TMP/24.md" <<'__CARD_BODY__'
**Objetivo:** um use case reaproveitado pela entrada HTTP e pela SQS.

### Fluxo sugerido (tudo dentro de **uma** transação SQL)
1. [ ] Validar a entrada e montar a `WagerTransaction` (rejeitar `OPENING` vindo de fora)
2. [ ] Calcular o `payloadHash`
3. [ ] `INSERT ... ON CONFLICT (idempotency_key) DO NOTHING`
   - se já existia: hash igual → **replay** (retorna o resultado gravado); hash diferente → **conflito de idempotência**
4. [ ] (Entrada SQS) inserir no inbox na mesma transação
5. [ ] `SELECT wallet ... FOR UPDATE`
6. [ ] Validar wallet, player e moeda
7. [ ] Se exige referência: buscar por `(providerId, referenceExternalTransactionId)`
   - não achou → `PENDING_REFERENCE` + evento, com `next_attempt_at`
   - achou → aplicar `ReferencePolicy`
8. [ ] Aplicar no aggregate (`debit`/`credit`) ou nada (LOSS), ou `reject(code)`
9. [ ] Gravar wallet, ledger, transação (com o resultado observado) e eventos na outbox
10. [ ] Commit; o resultado volta para o caller

### Atenção
- [ ] Transações REJECTED também são persistidas, para o replay devolver a mesma rejeição
- [ ] Violação do índice "reverter uma vez" vira `REFERENCE_ALREADY_REVERSED`, não erro 500
- [ ] Erro de conexão/timeout vira **erro transitório** (não marca a transação como FAILED)
- [ ] Nenhuma publicação externa dentro da transação (só gravar na outbox)

### Pronto quando
- BET, WIN, LOSS, REFUND, ROLLBACK funcionam ponta a ponta contra o Postgres real
__CARD_BODY__
create_issue '3.3 Use case: ProcessWagerTransaction (o fluxo principal)' "$TMP/24.md" '3 · Casos de uso e concorrência' 'concorrência' 'persistência' 'domínio'
cat > "$TMP/25.md" <<'__CARD_BODY__'
### Fazer
- [ ] Teste: mesma requisição 2× em sequência → a segunda retorna `idempotentReplay: true` com o **mesmo saldo** da primeira
- [ ] Teste: mesma key com payload diferente → conflito
- [ ] Teste: **mesma aposta 50× em paralelo** (`Promise.all`) → exatamente 1 débito, 49 replays
- [ ] Teste: replay de uma transação REJECTED retorna a mesma rejeição
- [ ] Teste: replay de uma PENDING_REFERENCE

### Pronto quando
- Todos verdes, e a invariante saldo == ledger checada no fim de cada teste
__CARD_BODY__
create_issue '3.4 Idempotência sob corrida: replay e conflito' "$TMP/25.md" '3 · Casos de uso e concorrência' 'concorrência' testes
cat > "$TMP/26.md" <<'__CARD_BODY__'
### Fazer
- [ ] Teste com paralelismo real (duas conexões/transações ao mesmo tempo, sem mock)
- [ ] Verificar: exatamente 1 PROCESSED, 1 REJECTED (`INSUFFICIENT_FUNDS`), saldo final 20.00, exatamente 1 lançamento DEBIT
- [ ] Reenviar as duas → nada muda (replay)
- [ ] Teste: wallets diferentes processadas em paralelo não se bloqueiam (medir que rodam concorrentes)
- [ ] Rodar o teste 20× seguidas para detectar flakiness

### Pronto quando
- Passa sempre, não "às vezes"
__CARD_BODY__
create_issue '3.5 Cenário obrigatório: 100.00, duas apostas de 80.00 simultâneas' "$TMP/26.md" '3 · Casos de uso e concorrência' 'concorrência' testes

# ---- 4 · API HTTP
cat > "$TMP/27.md" <<'__CARD_BODY__'
**Objetivo:** o provedor decide se reenvia só pelo status, sem ler a mensagem.

### Decidir e documentar (sugestão)
| Situação | Status |
|---|---|
| criado (wallet) | 201 |
| processado / replay | 200 (`idempotentReplay` no corpo) |
| aceito, aguardando referência | 202 |
| payload inválido | 400 |
| não encontrado | 404 |
| conflito de idempotência / wallet duplicada | 409 |
| rejeição de regra de negócio | 422 (com `failureCode` e `transactionId`) |
| falha transitória de infraestrutura | 503 + `Retry-After` |

### Fazer
- [ ] Parser/validador de entrada (zod ou valibot; ou validação manual), convertendo para o comando do use case
- [ ] Exception filter global que traduz erros de domínio/aplicação → status + corpo padrão `{ code, message, ... }`
- [ ] Nunca vazar stack trace ou SQL na resposta
- [ ] Tabela no ARCHITECTURE.md

### Pronto quando
- O mesmo tipo de erro retorna o mesmo status em todos os endpoints
__CARD_BODY__
create_issue '4.1 Validação de entrada e mapeamento de status HTTP' "$TMP/27.md" '4 · API HTTP' api docs
cat > "$TMP/28.md" <<'__CARD_BODY__'
### Fazer
- [ ] `POST /wallets` → OpenWallet
- [ ] `GET /wallets/:walletId`
- [ ] `GET /wallets/:walletId/ledger?cursor=&limit=50`
  - cursor **opaco e estável**: base64url de `(created_at, id)` do último item
  - `limit` com máximo
  - resposta `{ items, nextCursor }`
- [ ] Respostas com `Money` no formato `{ amount: "25.00", currency: "BRL" }`

### Testes
- [ ] paginação percorre tudo sem duplicar/pular, mesmo inserindo durante a leitura
- [ ] cursor inválido → 400

### Pronto quando
- Os 3 endpoints com testes de integração
__CARD_BODY__
create_issue '4.2 Endpoints de wallet: criar, consultar, ledger paginado' "$TMP/28.md" '4 · API HTTP' api
cat > "$TMP/29.md" <<'__CARD_BODY__'
### Fazer
- [ ] `POST /wagering/transactions`
  - header `Idempotency-Key` **obrigatório** (ausente → 400)
  - a key do header é a fonte da verdade
  - resposta `{ transactionId, status, balance, idempotentReplay }`
- [ ] `GET /wagering/transactions/:transactionId`
- [ ] `GET /providers/:providerId/wagering/transactions/:externalTransactionId`

### Testes
- [ ] cada `kind` via HTTP
- [ ] sem header → 400; conflito → 409; sem saldo → 422; referência ausente → 202

### Pronto quando
- Todos os cenários da tabela de status cobertos por teste
__CARD_BODY__
create_issue '4.3 Endpoints de wagering: submeter e consultar transações' "$TMP/29.md" '4 · API HTTP' api 'concorrência'
cat > "$TMP/30.md" <<'__CARD_BODY__'
**Não vale pontos.** Faça o mínimo agora; Keycloak fica para os opcionais.

### Fazer
- [ ] `AuthGuard` no-op aplicado nas rotas (exceto health)
- [ ] Porta `ProviderIdentityPort` (quem é o provedor autenticado) com implementação que confia no payload
- [ ] Mesmo sem auth, validar no domínio que o `providerId` da mensagem é consistente com a referência
- [ ] ARCHITECTURE.md: por que não implementou e qual desenho adotaria (OIDC client credentials por provedor, `providerId` vindo do token)

### Pronto quando
- Trocar o guard no-op por um real não exige mexer nos use cases
__CARD_BODY__
create_issue '4.4 Autenticação: ponto de extensão documentado' "$TMP/30.md" '4 · API HTTP' api docs

# ---- 5 · Mensageria SQS
cat > "$TMP/31.md" <<'__CARD_BODY__'
### Tópicos
- [ ] Standard x FIFO; `MessageGroupId` (use `walletId`) e `MessageDeduplicationId`
- [ ] Por que a dedup do FIFO (janela de 5 min) **não** substitui o inbox
- [ ] Long polling (`WaitTimeSeconds`), `MaxNumberOfMessages`
- [ ] Visibility timeout, `ChangeMessageVisibility`, `ApproximateReceiveCount`
- [ ] `DeleteMessage` = ack
- [ ] Redrive policy e `maxReceiveCount` → DLQ
- [ ] SDK: `bun add @aws-sdk/client-sqs`

### Pronto quando
- Você explica o que acontece se o processo morrer entre o commit e o `DeleteMessage`
__CARD_BODY__
create_issue '5.1 Estudo: SQS (FIFO, visibility timeout, DLQ)' "$TMP/31.md" '5 · Mensageria SQS' estudo mensageria
cat > "$TMP/32.md" <<'__CARD_BODY__'
### Fazer
- [ ] Loop de polling como provider do Nest (inicia em `onApplicationBootstrap`)
- [ ] Parse e validação do envelope `{ messageId, type, occurredAt, data }`; mensagem malformada → DLQ (erro permanente)
- [ ] Chamar **o mesmo** `ProcessWagerTransaction` da API, passando o `messageId` para o inbox
- [ ] Inbox `(consumerName, messageId)` gravado na mesma transação; se já existia → ack sem reprocessar
- [ ] `DeleteMessage` **somente após o commit**
- [ ] Classificar erros:
  - negócio (REJECTED) → ack (é terminal)
  - transitório (DB fora, timeout) → não dá ack; aumentar visibility com backoff
  - permanente → deixar ir para a DLQ (ou enviar explicitamente) e marcar FAILED se fizer sentido
- [ ] Concorrência do consumer configurável (N mensagens em paralelo)
- [ ] Script/CLI para publicar mensagens de teste na fila

### Pronto quando
- Uma BET enviada pela fila tem o mesmo efeito que pela API, e reenviar a mensagem não duplica nada
__CARD_BODY__
create_issue '5.2 Consumer SQS reutilizando o use case' "$TMP/32.md" '5 · Mensageria SQS' mensageria 'concorrência'
cat > "$TMP/33.md" <<'__CARD_BODY__'
### Fazer
- [ ] `app.enableShutdownHooks()`
- [ ] No `onModuleDestroy`/`beforeApplicationShutdown`: parar o polling, esperar as mensagens em andamento (com timeout)
- [ ] Mensagens recebidas e não iniciadas → `ChangeMessageVisibility(0)` para voltarem à fila
- [ ] O mesmo para os workers (outbox, pending reference): terminar o lote atual
- [ ] Logar início e fim do shutdown

### Testes
- [ ] Enviar SIGTERM durante processamento → nenhuma mensagem perdida nem duplicada

### Pronto quando
- `docker compose stop` não deixa estado inconsistente
__CARD_BODY__
create_issue '5.3 Graceful shutdown (SIGTERM)' "$TMP/33.md" '5 · Mensageria SQS' mensageria

# ---- 6 · Outbox e workers
cat > "$TMP/34.md" <<'__CARD_BODY__'
### Fazer
- [ ] Loop agendado (intervalo configurável)
- [ ] Reivindicar lote: `SELECT ... WHERE published_at IS NULL AND next_attempt_at <= now() ORDER BY occurred_at LIMIT n FOR UPDATE SKIP LOCKED`
- [ ] Publicar na fila de eventos (SQS) com `MessageDeduplicationId = eventId`
- [ ] Sucesso → `markPublished`; erro → `scheduleRetry` (backoff)
- [ ] Decidir: reivindicar e publicar dentro da mesma transação (lock seguro enquanto publica) ou "lease" com `locked_until`. Documentar o trade-off
- [ ] Aceitar que pode haver publicação duplicada (at-least-once); o consumidor deduplica por `eventId`
- [ ] Métrica de **outbox lag** (idade do evento pendente mais antigo)

### Testes
- [ ] dois publishers simultâneos → cada evento publicado uma vez (ou duplicata segura)
- [ ] commit → processo morre antes de publicar → outra instância publica
- [ ] SQS fora do ar → retry com backoff, nada perdido

### Pronto quando
- Os 3 testes passam com processos/instâncias reais
__CARD_BODY__
create_issue '6.1 Worker publicador da outbox (multi-instância)' "$TMP/34.md" '6 · Outbox e workers' mensageria 'concorrência'
cat > "$TMP/35.md" <<'__CARD_BODY__'
### Fazer
- [ ] Buscar transações `PENDING_REFERENCE` vencidas com `FOR UPDATE SKIP LOCKED`
- [ ] Reprocessar pelo mesmo caminho do use case (lock da wallet etc.)
- [ ] Backoff exponencial por tentativa (`attempts`, `next_attempt_at`)
- [ ] Definir e justificar o limite (ex.: N tentativas ou TTL de X minutos)
- [ ] Esgotou → `REJECTED` com `REFERENCE_NOT_FOUND` + evento `WagerTransactionRejected`
- [ ] (Opcional) ao processar uma transação, "acordar" pendentes que a referenciam, zerando o `next_attempt_at`

### Testes
- [ ] ROLLBACK chega antes da BET → fica pendente → BET chega → ROLLBACK é aplicado
- [ ] REFUND sem referência nunca chega → rejeitado depois do limite
- [ ] dois workers não processam a mesma pendente

### Pronto quando
- Os 3 cenários passam e o limite está justificado no ARCHITECTURE.md
__CARD_BODY__
create_issue '6.2 Worker de PENDING_REFERENCE (referências fora de ordem)' "$TMP/35.md" '6 · Outbox e workers' mensageria 'concorrência'

# ---- 7 · Operação e observabilidade
cat > "$TMP/36.md" <<'__CARD_BODY__'
### Fazer
- [ ] `POST /wallets/:walletId/reconciliation`
- [ ] Calcular o saldo pelo ledger (`SUM` com sinal por direção, em SQL, como `NUMERIC`)
- [ ] Comparar com o saldo armazenado → `{ storedBalance, calculatedBalance, difference, consistent, checkedEntries }`
- [ ] Divergência: **não corrigir**; logar como `error`, incrementar a métrica e sinalizar na resposta
- [ ] Reaproveitar como helper de teste ("invariante final")

### Pronto quando
- Forçar uma divergência no banco (desabilitando a trigger num teste) é detectada e reportada
__CARD_BODY__
create_issue '7.1 Reconciliação de wallet' "$TMP/36.md" '7 · Operação e observabilidade' api observabilidade
cat > "$TMP/37.md" <<'__CARD_BODY__'
### Fazer
- [ ] `GET /health/live` → 200 se o processo responde (sem tocar dependências)
- [ ] `GET /health/ready` → `SELECT 1` no Postgres + `GetQueueAttributes` no SQS, com timeout curto; 503 se algum falhar
- [ ] Sem autenticação
- [ ] (Opcional) `@nestjs/terminus`
- [ ] Healthcheck do serviço `app` no docker-compose usando `/health/ready`

### Pronto quando
- Derrubar o Postgres faz o ready ir para 503 e o live continuar 200
__CARD_BODY__
create_issue '7.2 Health checks: liveness e readiness' "$TMP/37.md" '7 · Operação e observabilidade' observabilidade api
cat > "$TMP/38.md" <<'__CARD_BODY__'
### Fazer
- [ ] Logger JSON (`pino` / `nestjs-pino`)
- [ ] Contexto por request/mensagem com `AsyncLocalStorage` (ou `nestjs-cls`): `correlationId`, `messageId`, `transactionId`, `walletId`, `providerId`
- [ ] `correlationId` vem do header `X-Correlation-Id` ou da mensagem; se não vier, é gerado; e propaga para os eventos da outbox
- [ ] `redact` para dados sensíveis; **não** logar payload financeiro completo
- [ ] Logs-chave: transação processada/rejeitada, replay, conflito, retry, DLQ, divergência de reconciliação

### Pronto quando
- Um único `correlationId` permite seguir uma transação da API até a publicação do evento
__CARD_BODY__
create_issue '7.3 Logs estruturados com correlationId' "$TMP/38.md" '7 · Operação e observabilidade' observabilidade
cat > "$TMP/39.md" <<'__CARD_BODY__'
### Fazer
- [ ] `bun add prom-client` e endpoint `GET /metrics`
- [ ] Métricas mínimas:
  - `wager_transactions_total{status,kind}`
  - `idempotency_duplicates_total{source}` (replay/inbox)
  - `idempotency_conflicts_total`
  - `processing_retries_total{reason}`
  - `dlq_messages_total`
  - `lock_conflicts_total` (lock timeout/serialization)
  - `outbox_lag_seconds` (gauge)
  - `wager_processing_duration_seconds` (histogram)
  - `reconciliation_divergences_total`
- [ ] Atenção à cardinalidade: nunca usar `walletId` como label

### Pronto quando
- `/metrics` mostra tudo isso depois de rodar os testes de concorrência
__CARD_BODY__
create_issue '7.4 Métricas (Prometheus)' "$TMP/39.md" '7 · Operação e observabilidade' observabilidade

# ---- 8 · Testes de integração e caos
cat > "$TMP/40.md" <<'__CARD_BODY__'
### Fazer
- [ ] Separar os scripts: `test:unit` (só `src/**/*.spec.ts`), `test:integration`, `test:concurrency`
- [ ] Antes da suíte: aplicar migrations no banco de teste e criar/limpar as filas
- [ ] Entre testes: `TRUNCATE` (lembrando da trigger do ledger: use uma role de teste ou `session_replication_role`)
- [ ] Helpers: `createWallet()`, `submit()`, `sendToQueue()`, `waitUntil(cond, timeout)`
- [ ] Helper `assertLedgerInvariant(walletId)` chamado no `afterEach`
- [ ] Opção: `testcontainers` para subir Postgres/LocalStack por suíte, em vez do compose

### Pronto quando
- `bun run test:integration` roda do zero com um comando, depois do `docker compose up`
__CARD_BODY__
create_issue '8.1 Infra de testes: banco real, LocalStack e helpers' "$TMP/40.md" '8 · Testes de integração e caos' testes setup
cat > "$TMP/41.md" <<'__CARD_BODY__'
### Cenários
- [ ] **Atomicidade**: falha injetada depois de gravar o ledger e antes do commit → wallet, ledger, inbox e outbox não têm nada
- [ ] **Inbox/redelivery**: mesma mensagem SQS entregue 2× → 1 efeito
- [ ] **Retry**: Postgres indisponível temporariamente → a mensagem volta e é processada depois
- [ ] **DLQ**: mensagem permanentemente inválida → cai na DLQ após `maxReceiveCount`
- [ ] **Publishers concorrentes** sobre a mesma outbox
- [ ] **Recuperação após reinício**: derrubar o app no meio, subir de novo, e o estado final fica consistente

### Pronto quando
- Todos passam usando Postgres e SQS reais (sem mock)
__CARD_BODY__
create_issue '8.2 Testes de integração: atomicidade, inbox, retry, DLQ, restart' "$TMP/41.md" '8 · Testes de integração e caos' testes mensageria
cat > "$TMP/42.md" <<'__CARD_BODY__'
### Fazer
- [ ] Subir 3 processos do app (`Bun.spawn` com portas diferentes, ou `docker compose up --scale app=3`)
- [ ] Disparar carga concorrente distribuída entre as instâncias sobre a **mesma** wallet
- [ ] **Worker morto entre commit e ack**: hook de teste (ex.: env `CRASH_AFTER_COMMIT=1`) que dá `process.exit` antes do `DeleteMessage`; a mensagem volta e outra instância apenas confirma (inbox)
- [ ] REFUND/ROLLBACK entregue antes da referência, com instâncias diferentes processando cada um
- [ ] Reinício do serviço inteiro e verificação final da consistência de todas as wallets
- [ ] Rodar várias vezes para pegar flakiness

### Pronto quando
- Invariante saldo == ledger vale para todas as wallets ao fim de cada cenário
__CARD_BODY__
create_issue '8.3 Testes com ≥ 3 instâncias e falhas reais' "$TMP/42.md" '8 · Testes de integração e caos' testes 'concorrência'

# ---- 9 · Documentação e portfólio
cat > "$TMP/43.md" <<'__CARD_BODY__'
### Conteúdo
- [ ] O que é o projeto, escrito com suas palavras (sem copiar o enunciado da empresa)
- [ ] Stack e diagrama de alto nível (Mermaid)
- [ ] Pré-requisitos e setup (`bun install`, `docker compose up -d`, migrations)
- [ ] Todos os comandos (`dev`, `test:unit`, `test:integration`, `test:concurrency`, `lint`, `typecheck`)
- [ ] Exemplos `curl` dos endpoints e de envio de mensagem para a fila
- [ ] Link para o ARCHITECTURE.md

### Pronto quando
- Alguém clona e roda tudo seguindo só o README
__CARD_BODY__
create_issue '9.1 README.md' "$TMP/43.md" '9 · Documentação e portfólio' docs
cat > "$TMP/44.md" <<'__CARD_BODY__'
### Seções
- [ ] Prioridades e fronteiras (camadas, módulos, regra de dependência)
- [ ] Money: decimal.js, `NUMERIC(20,2)`, string no contrato
- [ ] ORM e estratégia transacional (MikroORM, records + mappers)
- [ ] Concorrência (estratégia + justificativa + hot wallet)
- [ ] Idempotência (key, algoritmo do hash, replay, conflito)
- [ ] Schema: tabela de constraints e qual invariante cada uma protege
- [ ] Diagrama de estados da WagerTransaction
- [ ] Ledger e reconciliação
- [ ] Referências fora de ordem (backoff, limite)
- [ ] Tabela de FailureCodes
- [ ] Mapeamento de status HTTP
- [ ] Inbox, outbox, SQS, DLQ, shutdown
- [ ] Observabilidade
- [ ] Autenticação (decisão)
- [ ] Interpretações adotadas e limitações conhecidas

### Pronto quando
- Cada decisão tem "o quê", "por quê" e "o que eu perdi com isso"
__CARD_BODY__
create_issue '9.2 ARCHITECTURE.md: decisões, trade-offs e limitações' "$TMP/44.md" '9 · Documentação e portfólio' docs
cat > "$TMP/45.md" <<'__CARD_BODY__'
### Fazer
- [ ] Workflow: `bun install --frozen-lockfile`, `typecheck`, `lint`, `test:unit`
- [ ] Job de integração com `services:` postgres e localstack (ou compose) rodando `test:integration`
- [ ] Badge de CI no README
- [ ] Descrição, topics e link do README no repo do GitHub
- [ ] Revisar commits/branches, criar uma tag `v1.0.0`

### Pronto quando
- CI verde no `main`
__CARD_BODY__
create_issue '9.3 CI no GitHub Actions + acabamento' "$TMP/45.md" '9 · Documentação e portfólio' setup testes

# ---- 10 · Opcionais
cat > "$TMP/46.md" <<'__CARD_BODY__'
### Fazer
- [ ] Ferramenta: k6 ou autocannon (ou script com Bun)
- [ ] Cenários: muitas wallets (distribuído) x uma hot wallet
- [ ] Registrar ambiente (máquina, nº de instâncias, pool), metodologia, throughput, p50/p95/p99, taxa de erro, conflitos de lock e outbox lag
- [ ] Análise honesta dos gargalos
__CARD_BODY__
create_issue '10.1 Teste de carga (bun run test:load)' "$TMP/46.md" '10 · Opcionais' opcional testes
cat > "$TMP/47.md" <<'__CARD_BODY__'
### Fazer
- [ ] Serviço no docker-compose com realm/clients pré-configurados (import)
- [ ] Client credentials por provedor; `providerId` extraído do token
- [ ] Guard real validando JWT (JWKS) no lugar do no-op
- [ ] Rejeitar quando o `providerId` do corpo for diferente do token
__CARD_BODY__
create_issue '10.2 Autenticação com Keycloak ou Zitadel' "$TMP/47.md" '10 · Opcionais' opcional api
cat > "$TMP/48.md" <<'__CARD_BODY__'
### Fazer
- [ ] Traces HTTP → use case → SQL → SQS com OpenTelemetry
- [ ] Prometheus + Grafana no compose com um dashboard (status, latência, outbox lag, DLQ)
__CARD_BODY__
create_issue '10.3 OpenTelemetry e dashboard' "$TMP/48.md" '10 · Opcionais' opcional observabilidade
cat > "$TMP/49.md" <<'__CARD_BODY__'
### Fazer
- [ ] Conta da "casa" (house account) por moeda
- [ ] Cada transação gera débito numa conta e crédito na outra; soma global sempre zero
- [ ] Reconciliação global
__CARD_BODY__
create_issue '10.4 Ledger de partidas dobradas (double-entry)' "$TMP/49.md" '10 · Opcionais' opcional 'domínio'

echo "Done: 49 cards."