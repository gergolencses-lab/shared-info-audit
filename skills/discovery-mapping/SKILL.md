---
name: discovery-mapping
description: >
  This skill should be used when the user asks to "scan SharePoint for oversharing",
  "find broadly shared sensitive files", "audit Google Drive sharing", "map exposure
  across SharePoint and Drive", "check what's overshared", "find misplaced company
  files in personal OneDrive", or as the first stage of a scheduled oversharing scan.
version: 0.1.0
---

# Discovery & Exposure Mapping

The first stage of the oversharing-detection pipeline. Cheap, metadata-only, and designed to run frequently (daily or weekly) since it never reads file content — only location and, where available, sharing metadata. Produces a ranked candidate list that the `sensitivity-classifier` skill consumes next.

## Two things this skill looks for

Most oversharing tooling looks for one pattern: sensitive content sitting somewhere too many people can see it. This skill looks for that, plus its mirror image: important business content sitting somewhere too few systems protect it — a personal OneDrive or My Drive that gets wiped the day its owner leaves. Tag every finding as one of:

- **broad** — sitting in a location shared with an entire team, site, or org
- **external** — shared outside the organization (only detectable where real permission data exists — see platform notes)
- **misplaced** — business-critical-looking content sitting in an individual's personal storage rather than a team location

## Before starting

Detect which platform connector(s) are available (Microsoft 365 SharePoint/OneDrive tools, Google Workspace Drive tools, or both). Tell the user which platform(s) this run covers. If a platform the user expects isn't connected, say so plainly rather than silently skipping it.

Read `references/platform-adapters.md` for the exact tool-by-tool mapping and the location-heuristic details before the first run in a new environment — the two platforms are not symmetric and the differences matter.

## Process

1. **Enumerate locations.** List the SharePoint sites, OneDrive personal areas, and/or Google Shared Drives in scope. If there is no way to enumerate all sites automatically, ask the user for a list once and remember it for the session.
2. **Fan out.** Dispatch one `discovery-scanner` subagent per location, in parallel, via the Task tool. Cap concurrent subagents — start with the locations most likely to matter (sites with "HR," "Finance," "Admin," "Legal," "Contracts" or similar in the name) rather than spawning one subagent per location in a 40-site tenant on the first pass. Multi-agent fan-out costs roughly an order of magnitude more tokens than a single-threaded scan — bound it deliberately rather than maximizing parallelism for its own sake.
3. **Aggregate.** Collect every subagent's `{path, platform, apparent_scope, note}` results into one list.
4. **Rank.** Sort broad and external findings above misplaced findings, and within each group put anything with an HR/Finance/Legal/Contract signal in the name or path first.
5. **Hand off.** Write the ranked list to a structured output the `sensitivity-classifier` skill can read next (the top of the list is what gets the expensive content-reading treatment first).

## What this skill cannot tell you

Be explicit about this in every output, not just once at setup: on Microsoft 365, the current connector has no way to read actual sharing/permission data (no "Everyone except external," no anonymous-link detection, no guest list). The **broad** vs **narrow** call for SharePoint/OneDrive is a location-based inference, not a measurement. Getting the real answer requires the customer's own SharePoint Admin Center → Data Access Governance reports, or the Microsoft Graph `/permissions` API with admin consent — neither of which this skill can reach on its own. On Google Workspace, by contrast, the connector can read real permission data, so **broad**/**external** calls there are actual measurements, not inferences. Never let a report imply the same confidence level for both platforms.

## Output schema

```
{
  "platform": "microsoft365 | google_workspace",
  "location": "site or drive name",
  "path": "full path",
  "scope_signal": "broad | external | narrow | misplaced",
  "confidence": "measured | inferred",
  "note": "why this was flagged"
}
```

## Additional resources

- **`references/platform-adapters.md`** — exact tool mapping, location-heuristic rules, and platform-specific limitations for both Microsoft 365 and Google Workspace.
