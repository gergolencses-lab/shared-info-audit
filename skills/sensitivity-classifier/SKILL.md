---
name: sensitivity-classifier
description: >
  This skill should be used when the user asks to "classify sensitivity", "check if
  this file is confidential", "find unlabeled sensitive files", "check for label
  mismatches", "does this need a sensitivity label", or as the second stage of the
  oversharing pipeline following discovery-mapping.
version: 0.1.0
---

# Label-Aware Sensitivity Classifier

The second stage of the pipeline. Takes the ranked candidate list from `discovery-mapping` and determines how sensitive each item actually is — without either blindly trusting existing labels or blindly re-classifying everything from scratch.

## Why label-aware, not blind content-reading

Both Microsoft 365 (Purview sensitivity labels) and Google Workspace (Drive classification labels) already have native tagging systems. But audits of real Microsoft 365 tenants have repeatedly found fewer than 15% of documents actually carry a label even where a labeling policy is fully configured — meaning most files have no signal to check, but the ones that do have a label are worth a different kind of scrutiny: does the label actually match the content? See `references/taxonomy.md` for the full taxonomy definitions, the default Purview/Google label systems, and the mismatch concept in more depth.

## Process

1. **Take the candidate list** from `discovery-mapping`, highest-priority (broad/external, then misplaced) items first.
2. **Batch it.** Group candidates into bounded batches — by source site/folder/drive is usually natural — sized so each batch is small enough for one subagent to handle without a huge context window.
3. **Fan out.** Dispatch one `sensitivity-classifier-worker` subagent per batch, in parallel, via the Task tool. This is the expensive stage of the pipeline (it reads actual file content), so only run it against what discovery-mapping already flagged as worth a look — never a blanket re-scan of everything, and only re-run against the delta (new or newly-broadened items) on repeat scans, not the full history again.
4. **Each worker follows the label-first branch**: check for an existing label (free) → no label found, full content read against the generic taxonomy → label present, lightweight mismatch spot-check instead of full re-classification. (The full branch logic lives in each worker's own agent definition — this skill just dispatches and aggregates.)
5. **Aggregate** every worker's findings into one list: `{path, platform, existing_label_or_none, inferred_sensitivity, confidence, mismatch, minimal_evidence}`.
6. **Hand off** the aggregated list to `risk-scoring-reporting`.

## Evidence discipline

Never let a worker's output — or this skill's aggregation of it — reproduce actual sensitive content (real ID numbers, real credentials, real financial figures). Evidence should describe what was found ("contains a national ID number and a bank account number"), not copy it. This matters both for the report's own security and because over-quoting sensitive data back into a report file just relocates the exposure instead of flagging it.

## A mismatch is not the same as "no label"

Treat these as genuinely different finding types when reporting: a file with **no label** on sensitive content is a coverage gap (nobody classified it). A file with a label that **doesn't match** its content is a judgment-call gap (somebody classified it, and got it wrong) — this is usually the more actionable finding, since it means a real decision was made that a policy owner can now correct directly, rather than a fresh classification exercise. Flag mismatches distinctly in the output, not folded into a generic "sensitive" bucket.

## Additional resources

- **`references/taxonomy.md`** — the full generic sensitivity taxonomy, default Purview and Google Workspace label systems, and the mismatch pattern in more depth.
