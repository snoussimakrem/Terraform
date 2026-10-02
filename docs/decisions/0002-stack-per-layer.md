# ADR 0002: One state per layer (numbered stacks)

**Status:** Accepted

## Context
A single state for everything is slow, has a huge blast radius, serializes all work behind one lock, and forces everyone to have every credential.

## Decision
Split each environment into stacks by rate-of-change and risk: network → data-lake → cluster → platform → data-services. Stacks communicate via explicit outputs read with terraform_remote_state.

## Consequences
+ small plans, small blast radius, parallel work, least-privilege per stack. − cross-stack ordering must be managed (Makefile/CI order); remote_state couples stacks to each other's output names (treat outputs as a public API).
