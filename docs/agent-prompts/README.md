# Optional Agent Prompts

These prompts are maintainer-invoked, non-normative aids for applying the
common protocol. The repository publishes them so a maintainer can copy or
reference a bounded invocation contract without duplicating the normative
rules.

- [Stability and consistency cycle](stability-and-consistency-cycle.md)

Using a prompt is opt-in. Merely adopting, pinning, or updating the protocol
does not install, create, schedule, or activate a goal, recurring task,
automation, workflow, scheduler, background loop, or next invocation. The
consumer's pinned [PROTOCOL.md](../../PROTOCOL.md) and applicable repository-local instructions
remain authoritative.

The default report-only mode may establish local convergence evidence, but it
cannot complete the normative cycle or enter `Waiting`. Without separately
authorized final-push authority, it reports the push-eligible cycle as
`Blocked`.

meAndAI maintainers use the files in this directory. A submodule consumer can
resolve the same files below `.ai/protocol/docs/agent-prompts/`. A
repository-reference consumer resolves them at its provider-configured
immutable ref. Consumers do not need a consumer-owned copy.
