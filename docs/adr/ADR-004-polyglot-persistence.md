# ADR-004: Polyglot Persistence — PostgreSQL + MongoDB

**Date:** 2026-02
**Status:** Accepted

## Context

Multiple services with different data model characteristics need persistence. Options: single PostgreSQL for all, MongoDB for all, service-specific DB selection.

## Decision

Use **PostgreSQL 17** for relational/transactional services (financial, fitness) and **MongoDB 8** for the `gotoaws-sathish` service.

## Rationale

**PostgreSQL for financial and fitness services:**
- ACID transactions are critical for accounts, cards, and loans (financial integrity).
- Flyway migrations provide auditable, version-controlled schema evolution.
- `runs_schema` shared schema (with separate DB users per service) balances isolation with operational simplicity.
- PostgreSQL 17 supports JSON columns for semi-structured data without sacrificing relational query capabilities.

**MongoDB for gotoaws-sathish:**
- The AWS-bound service manages schema-flexible cloud resource metadata that evolves frequently.
- Mongock migrations provide the same version-controlled schema evolution story as Flyway, but for document collections.
- Replica set mode (`rs0`) enables change streams and ensures read concern majority for consistent reads.

**Separate PostgreSQL instances per domain:**
- event-service (:6433), mytracker (:5440), shedlock (:5441), runs-app (:5442) are isolated — a schema corruption in one does not cascade.
- Independent backup and restore per domain.

## Trade-offs

- Distributed transactions across PostgreSQL instances are not supported (each service owns its own DB).
- Operating 4 PostgreSQL instances and 1 MongoDB in Docker Compose is resource-intensive locally. Production uses managed cloud DBs (Azure PostgreSQL Flexible Server, AWS Aurora).

## Consequences

Each service's Docker Compose definition specifies its own PostgreSQL container or connects to the shared infrastructure container. Connection strings use environment variable substitution (`${garmindb}`) to support multiple deployment profiles without code changes.
