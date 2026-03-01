# ADR-003: Hybrid Messaging — RabbitMQ for App Events, Kafka for Data Streams

**Date:** 2026-02
**Status:** Accepted

## Context

The ecosystem has two distinct messaging needs:
1. **Application events** (account updates, GitHub cleanup triggers, card events) — low volume, request/reply or fan-out semantics
2. **Fitness data streams** (Strava activities, Garmin runs) — potentially high volume, needs schema evolution, consumer group replay

Using a single broker for both creates impedance mismatches.

## Decision

Use **RabbitMQ** for application events and **Apache Kafka** (3-node cluster) for fitness data streams with **Avro** serialization and **Confluent Schema Registry**.

## Rationale

**RabbitMQ for app events:**
- Topic exchange + DLX/DLQ pattern handles retry and poison message isolation.
- TTL of 10s prevents queue buildup from slow consumers.
- Fanout exchange broadcasts to multiple consumers simultaneously without coupling producers to consumers.
- Simpler operational model for low-volume, transactional events.

**Kafka for data streams:**
- Consumer groups allow independent services to replay the same Garmin/Strava event stream.
- Avro schema + Schema Registry enforces a contract between producers and consumers — breaking schema changes are detected at build time.
- Snappy compression reduces bandwidth for high-volume activity data.
- 3-node cluster with replication factor 3 and min ISR 2 provides fault tolerance.

## Trade-offs

- Running two message brokers increases operational complexity and Docker Compose resource usage.
- Developers need familiarity with both RabbitMQ and Kafka paradigms.

## Consequences

Kafka topic naming convention enforced via IAM (see iAC-NikeRuns): `app-*` prefix for topics, `cg-*` for consumer groups. RabbitMQ exchanges follow naming convention: `x.sathishprojects.*`. Dead letter queues (DLQ) are created for every critical queue.
