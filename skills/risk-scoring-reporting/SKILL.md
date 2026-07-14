---
name: risk-scoring-reporting
description: >
  This skill should be used when the user asks to "generate the oversharing report",
  "build the risk digest", "prioritize these findings", "what's our biggest exposure
  right now", or as the third stage of the pipeline following sensitivity-classifier.
version: 0.1.0
---

# Risk Scoring & Reporting

The third stage. Unlike the first two, this is pure synthesis — it does not fan out to subagents. It takes the exposure signal from `discovery-mapping` and the sensitivity signal from `sensitivity-classifier` and produces one prioritized, human-readable digest. A single coherent pass produces a better-prioritized report than several independent workers each seeing only part of the picture.

## Scoring

Combine `scope_signal` (broad / external / narrow / misplaced) with `inferred_sensitivity` and `mismatch` into a priority tier:

- **Critical**: high-sensitivity content (PII, credentials, financial, health) in a broad or external location, OR any mismatch involving Highly-Confidential-grade content
- **High**: high-sensitivity content in a narrow-but-notable location, OR misplaced business-critical content (contracts, financial models, deliverables sitting in personal storage)
- **Medium**: moderate-sensitivity content (HR, legal, strategic) in a broad location, or any unresolved mismatch not already Critical
- **Low**: everything else that was still worth flagging

## Report structure

Follow this shape — it is a proven structure, not a first draft:

1. **Critical findings** — table of file/location, why it's a problem, one line each
2. **Medium findings** — same, shorter
3. **Positive findings** — explicitly call out what's clean (no exposed credentials, GDPR docs properly structured, etc.). A report that's all bad news is less credible and less useful than one that shows the scan actually looked everywhere.
4. **What this scan could not verify** — front and center, not a footnote: name the Microsoft 365 permission-read limitation explicitly (see `discovery-mapping`'s own caveat) and anything else the pipeline couldn't confirm without admin-level access.
5. **Trend** — new findings since the last run, if a previous digest exists to compare against.

## Output

Prefer a Cowork artifact over a static file when this will be checked repeatedly (a live, re-openable dashboard beats a report that goes stale the moment it's read) — but a markdown or docx report is the right call for a one-off audit or something meant to be emailed or printed for a specific meeting. Ask which the user wants if it's not already obvious from context.

Do not send or distribute the report automatically. Hand it to the person who requested the scan; wider distribution (to IT, security, a compliance mailbox) is a decision for a human to make explicitly, not a default action.

## Handoff to remediation-assist

Do not automatically invoke `remediation-assist` for every Critical/High finding. List the findings and let the user pick which ones to act on — remediation is always a per-finding, human-initiated step, never a batch action this skill triggers on its own.
