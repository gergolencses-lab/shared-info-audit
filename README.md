# Exposure Audit

Scheduled, multi-agent detection of oversharing and misplaced sensitive content across Microsoft 365 (SharePoint / OneDrive / Teams) and Google Workspace (Drive / Gmail).

## Why this exists

Companies are connecting more capable AI agents (including Claude) to SharePoint and Google Drive. Neither platform's storage model is well understood by most employees — SharePoint, Teams Files, and OneDrive are the same underlying storage with different ownership models, and people routinely misjudge who can see what. A more capable search agent doesn't create that oversharing, but it makes previously-obscure oversharing much easier to actually find — including by people who shouldn't. This plugin proactively finds that exposure first, so an organization's own IT/security team can fix it.

This plugin does **not** try to detect company-specific secrets. It looks for generic categories of sensitive content (PII, credentials, financial, HR, legal, health, strategic) that apply the same way to any organization.

## Components

| Component | What it does |
|---|---|
| `discovery-mapping` (skill) | Stage 1 — cheap, metadata-only scan ranking locations by exposure breadth, across both platforms |
| `sensitivity-classifier` (skill) | Stage 2 — label-aware content classification: checks existing labels first, full-reads only the unlabeled majority, spot-checks the rest for label mismatches |
| `risk-scoring-reporting` (skill) | Stage 3 — combines exposure + sensitivity into one prioritized digest/report |
| `remediation-assist` (skill) | Stage 4 — human-gated only. Drafts a fix for one specific finding the user selects; never acts automatically |
| `plugin-guide` (skill) | Not a pipeline stage — answers conversational questions about what this plugin is useful for and where its limits are, without running a scan or reading the full manual |
| `discovery-scanner` (agent) | Subagent dispatched by discovery-mapping, one per site/drive, in parallel |
| `sensitivity-classifier-worker` (agent) | Subagent dispatched by sensitivity-classifier, one per batch, in parallel |
| `/scan-oversharing` (command) | Runs stages 1–3 end to end in one pass — the same pipeline a scheduled task runs unattended |
| audit-log hook | Appends a line to `audit-log.txt` every time a subagent is dispatched, as a best-effort supplementary trail (see caveat below) |

## Documentation

`docs/instruction-manual.pdf` (and its `.html` source) has the full picture: architecture diagram, what each skill does, the label-aware branch logic inside Skill 2, setup, the complete limitations table, and links to the underlying Microsoft/Google/NIST documentation this plugin's design leans on. Ask the plugin directly ("what does this do", "should I use this for X") for a quick conversational answer instead — that's what `plugin-guide` is for.

## Install

**As a Claude Code / Cowork plugin marketplace** (this repo doubles as its own marketplace):

```
/plugin marketplace add gergolencses-lab/shared-info-audit
/plugin install exposure-audit@lencses-plugins
```

**Manual:** clone or download [this repo](https://github.com/gergolencses-lab/shared-info-audit) and copy the folder into your plugins directory, or share it inside a Cowork chat as a `.plugin` zip — recipients can install it with one click.

## Setup

Connect at least one of: a Microsoft 365 connector (SharePoint search) or a Google Workspace connector (Drive search + permissions). Both is better than either alone, since the two platforms cover different parts of a typical company's storage.

To run this on a schedule rather than manually, set up a scheduled task that runs `/scan-oversharing`.

## Known limitations — read before relying on this

- **Microsoft 365 permission data is unavailable to this plugin.** The current SharePoint connector cannot read real sharing/permission metadata (no external-link detection, no guest list, no "Everyone except external"). Discovery falls back to a location-based heuristic (shared document library vs. personal OneDrive) that is a reasonable proxy, not a measurement. Getting the ground truth requires the organization's own SharePoint Admin Center → Data Access Governance reports, or the Graph `/permissions` API with admin consent.
- **Google Workspace permission data IS available** and used directly — that side of the scan is a real measurement, not an inference. Don't treat the two platforms' outputs as equally precise.
- **Scope is limited to what the running account can see.** The connector uses the logged-in user's own delegated access, not a service account or admin-wide access. One person's scan covers their own reachable slice of the tenant, not necessarily the whole organization.
- **The audit-log hook is best-effort, not compliance-grade.** It logs subagent dispatches while this plugin is active; it does not replace SOC 2 / HIPAA-grade activity logging, and Cowork's own audit logs currently do not capture this kind of scheduled agent work either.
- **Multi-agent fan-out costs more tokens than a single-threaded scan** — each skill bounds its own parallelism deliberately (prioritizing likely-risky locations first) rather than maximizing concurrency.

## Design principles

- Report, never auto-remediate. Every write-type action (label change, permission change, notification) is a draft a human explicitly approves — this is deliberate, not a missing feature, because a scheduled agent that can read files and act unattended is exactly the shape of a known prompt-injection attack pattern.
- Two exposure patterns, not one: classic oversharing (too many people can see it) and misplacement (too few systems protect it — business-critical content stranded in someone's personal storage, which disappears when they leave).
- Label-aware, not blind: check for an existing sensitivity label before doing an expensive full content read, and treat a mismatched label as a distinct, high-value finding rather than folding it into a generic "sensitive" bucket.
