# ADR-001: Spring Cloud Config Server for Centralized Configuration

**Date:** 2026-02
**Status:** Accepted

## Context

Managing configuration for 14+ independent microservices. Without centralization, each service embeds its own application.yml, requiring a rebuild/redeploy for any config change. Options: Spring Cloud Config Server, HashiCorp Vault, AWS Parameter Store, environment variables only.

## Decision

Use **Spring Cloud Config Server** backed by this Git repository.

## Rationale

- **Profile-aware:** Each service fetches `{service-name}-{profile}.yml` from this repo at startup — no code change for environment-specific config.
- **RSA encryption:** Sensitive values (DB passwords, API keys, Strava tokens) are stored encrypted with `{cipher}` prefix. Config Server decrypts on-the-fly using a private key.
- **Single source of truth:** All service configurations live in one auditable, version-controlled repository.
- **Hot refresh:** Spring Cloud Bus can trigger `@RefreshScope` beans without restarting services.
- **Zero infra overhead:** Runs as a simple Spring Boot app; backed by Git (no extra DB or Vault cluster required).

## Trade-offs

- Config Server becomes a critical dependency — services fail to start if it is unreachable. Mitigated by Kubernetes 3-replica deployment.
- Git-backed config has ~1-2s latency on startup fetch. Acceptable for service startup time.

## Consequences

All services must include `spring-cloud-starter-config` dependency and point `spring.config.import=configserver:http://...` to the Config Server URL. Config Server must start before all other services.
