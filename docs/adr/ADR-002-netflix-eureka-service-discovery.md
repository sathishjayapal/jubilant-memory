# ADR-002: Netflix Eureka for Service Discovery

**Date:** 2026-02
**Status:** Accepted

## Context

Microservices need to locate each other without hardcoded URLs. Options: Kubernetes DNS (kube-dns), Netflix Eureka, Consul, AWS Cloud Map.

## Decision

Use **Netflix Eureka** as the service registry (port 8070).

## Rationale

- **Spring-native:** `@EnableEurekaServer` / `@EnableDiscoveryClient` integrate directly with Spring Cloud LoadBalancer and Feign clients — minimal boilerplate.
- **Client-side load balancing:** Services cache the registry locally (fetch every 5s) and perform client-side load balancing. No central load balancer needed for service-to-service calls.
- **Self-healing:** Eureka's heartbeat mechanism evicts unhealthy instances automatically after 90s without disrupting healthy ones.
- **Dashboard:** Eureka's web UI at :8070 shows all registered services, their instances, and health status — useful for demo and debugging.

## Trade-offs

- Eureka is in maintenance mode at Netflix (Spring Cloud Eureka is still actively maintained).
- In Kubernetes, kube-dns handles service discovery natively. Running both is redundant but acceptable during the transition to full K8s deployment.
- Eureka's eventual consistency model means brief periods where a newly registered service is not visible to all peers.

## Consequences

`fetchRegistry: false` and `registerWithEureka: false` on the Eureka server itself (standard configuration). All client services fetch the registry every 5s (`registryFetchIntervalSeconds: 5`). Actuator endpoints (health, prometheus) are exposed for Eureka server monitoring.
