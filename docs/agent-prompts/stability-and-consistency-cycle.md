# Stability and Consistency Cycle Agent Prompt

This is optional, non-normative, copy/reference-only guidance for one bounded
invocation of the event-triggered mandate in `PROTOCOL.md` and
[DEC-0015](../decisions/DEC-0015-event-triggered-stability-cycles.md). It does
not create or activate a Codex goal, recurring task, automation, schedule,
workflow, scheduler, background loop, or next invocation. A maintainer must
deliberately invoke it through the tool and process of their choice.

Before invoking the prompt, supply these values:

- `Trigger context`: the material development increment or new failed evidence
  that caused this invocation.
- `Scan scope and exclusions`: the full tracked-project scope plus every
  inaccessible, generated, binary, external, or otherwise unreviewed area.
- `Validation budget`: a finite budget; the protocol default is one initial
  scan and, only after remediation changes the tree, one confirmation scan.
- `Publication mode`: `report-only` or `push-review-branch`. The default is
  `report-only`. That mode may establish local convergence evidence but cannot
  complete the normative cycle or enter `Waiting` without the final push.
- `Review branch and push authority`: required only for
  `push-review-branch`; name the review branch and separately authorize the
  ordinary converged final push. The mode name alone grants no Git authority.

Copy or reference the following prompt for one invocation:

```text
Execute one bounded, event-triggered stability and consistency cycle for this
repository.

Inputs
- Trigger context: <material development increment or new failed evidence>
- Scan scope and exclusions: <full tracked-project scope and exact exclusions>
- Validation budget: <finite pass and correction budget; default is one initial
  scan plus one confirmation scan only if remediation changed the tree>
- Publication mode: <report-only | push-review-branch; default report-only>
- Review branch and push authority: <absent, or exact branch plus explicit
  authority for its ordinary converged final push>

Authority and boundaries
1. Read and obey the exact pinned PROTOCOL.md, DEC-0015, every applicable
   repository instruction, and repository-local feature, decision, test, and
   memory records. Those sources are normative; this prompt cannot override
   them.
2. This invocation is not a self-running service. Do not create, schedule, or
   activate a goal, recurring task, automation, workflow, scheduler,
   background loop, heartbeat, or next invocation. End after reporting the
   outcome of this invocation.
3. Preserve unrelated user work. Do not invent project facts or silently
   expand scope. Record inaccessible or unreviewed scope explicitly.
4. The declared validation budget is finite. An unchanged scan must not be
   repeated. Missing authority, required input, an unresolved dependency cycle,
   or exhausted budget produces Blocked with exact evidence and next required
   input; it never produces a success claim.

Trigger gate
1. Confirm that the trigger is material development (including feature, bug,
   refactor, review, test, documentation, governance, or consistency work) or
   new failed evidence.
2. If the repository is Waiting and has neither new material development nor
   new failed evidence, stop without scanning or changing the tree. Report
   Waiting and the absent trigger.

Initial scan and triage
1. Scan the entire declared tracked-project scope at the highest practical
   detail. Cover the concerns required by PROTOCOL.md, and list every exclusion.
2. Document every observation with a stable finding identity and assign exactly
   one Gate 5 disposition: Blocking, AcceptedResidual,
   ExternalOrLegacyFollowUp, or OptionalImprovement. Preserve the authority,
   owner, rationale, evidence, and review condition required for non-Blocking
   dispositions.
3. Only unresolved Blocking findings enter the remediation queue. Record each
   queued finding's dependencies (or None), priority, severity, impact rank,
   evidence, and affected scope.
4. Build the ready set from satisfied dependencies first. Within that ready
   set, order findings by priority, severity, impact rank, and then stable
   identifier. Do not guess an order through a dependency cycle.

Correction cycle
1. Resolve one Blocking finding at a time, except for the smallest explicitly
   recorded dependency-coherent group that cannot be changed safely in
   isolation.
2. For each correction, implement the smallest coherent solution, run focused
   tests and other relevant verification, and perform a fresh-diff self-review
   before starting the next independent queue item. Record the solution,
   commands, results, review scope, and disposition of every review observation.
3. A Blocking finding caused or exposed by the correction remains in this
   cycle. Fix it in the current correction when coherent; otherwise add it to
   the queue with dependencies and priority. Do not relabel current-change debt
   as legacy or optional work.
4. Continue only while authority, required inputs, and the declared finite
   budget remain available. Otherwise report Blocked; do not claim convergence.

Convergence and completion
1. If the initial scan finds no unresolved Blocking finding, that scan is the
   convergence evidence. Do not run an unchanged confirmation scan.
2. If remediation changed the tree and emptied the queue, run the one budgeted
   confirmation scan. Add any new Blocking finding to the queue and continue
   only within the remaining finite budget.
3. Local convergence means declared tests pass and zero unresolved Blocking
   findings remain. Local convergence is not full normative cycle completion.
   AcceptedResidual, ExternalOrLegacyFollowUp, and OptionalImprovement
   observations remain visible but do not prevent local convergence under their
   protocol evidence contracts.
4. In report-only mode, do not commit or push. If the tree locally converged,
   report push-eligible evidence and `Blocked` on missing final-push authority;
   the normative cycle remains incomplete. Do not report `Waiting` or full
   cycle completion. Report changed files, test evidence, review evidence,
   remaining non-Blocking observations, exclusions, and unused scope.
5. In push-review-branch mode, push only when the maintainer separately granted
   authority for the exact review branch and the tree has converged. Perform an
   ordinary converged final push, record the resulting commit and ref in the
   issue or pull request after they exist, then report Waiting. If authority is
   absent, report push-eligible but `Blocked` on missing final-push authority
   without pushing or claiming completion.
6. Neither publication mode authorizes pushing a protected/default branch,
   opening or merging a pull request, closing an issue, deleting a branch,
   creating a tag, or creating a GitHub Release. Hosted CI or review evidence
   discovered later is a new failed-evidence trigger for a separately invoked
   cycle; this invocation must not start that next cycle itself.
```

The prompt intentionally ends after one invocation. A maintainer may configure
their own product-level recurring task or goal to invoke it later, but that
configuration, cadence, credentials, branch authority, and stop controls remain
outside this artifact and outside automatic protocol adoption or update.
