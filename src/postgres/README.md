# PostgreSQL Implementation

PostgreSQL schema implementation generated from the ISO 20022 Message
Definition Report, Part 2 (Payments Clearing and Settlement, Maintenance
2024-2025). Covers Section 10.2 "Message Datatypes" and the entirety of
Section 10.1 "Message Components", including 10.1.18 Remittance.
Message-level tables (pain/pacs/camt) are the remaining follow-on phase and
are not started yet.

## Structure

| Folder | Purpose |
| ------ | ------- |
| [schema/](schema/) | Deployable DDL and the automated test suite |
| [generators/](generators/) | Python scripts that regenerate the schema from source specs/registries |
| [config/](config/) | Persistent generator configuration (type field registry) |

## Status

This is a working draft carried over from initial exploratory work with a
colleague and an AI assistant. It has been exercised against a real
PostgreSQL 16 instance during development, but the automated tests are not
exhaustive and the generator scripts still contain some hardcoded paths from
their original development environment (see
[generators/README.md](generators/README.md)). Treat it as a solid
foundation, not a finished, production-hardened deliverable.

See [schema/README.md](schema/README.md) for deployment and testing.
